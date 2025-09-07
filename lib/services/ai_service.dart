import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_recipe.dart';

/// Service AI - Gemini 2.0 Flash.
/// Tampilkan alasan jika gagal supaya tidak bingung kenapa jatuh ke mock.
class AiService {
  // Baca dari --dart-define
  final String geminiApiKey =
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// indikator untuk UI/debug
  String lastProvider = 'mock';
  String lastError = '';

  Future<AiRecipe> getRecipeIdea(String dishName) async {
    // 1) API key kosong -> mock
    if (geminiApiKey.trim().isEmpty) {
      lastProvider = 'mock (key empty)';
      lastError = 'API key kosong';
      return getRecipeIdeaMock(dishName);
    }

    // 2) Coba Gemini
    try {
      final res = await _getFromGemini(dishName);
      lastProvider = 'gemini';
      lastError = '';
      return res;
    } catch (e) {
      // log alasan ke console & UI
      lastProvider = 'mock (fallback)';
      lastError = e.toString();
      // ignore: avoid_print
      print('Gemini failed → fallback to MOCK: $e');
      return getRecipeIdeaMock(dishName);
    }
  }

  /// Mock – selalu sama (biar gampang dikenali)
  Future<AiRecipe> getRecipeIdeaMock(String dishName) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final mock = {
      "title": "Nasi Goreng Rumahan",
      "ingredients": [
        "Nasi 1 piring",
        "Telur 1 butir",
        "Bawang putih 2 siung",
        "Kecap manis 1 sdm",
        "Garam, lada",
        "Minyak untuk menumis"
      ],
      "steps": [
        "Tumis bawang putih.",
        "Masukkan telur, orak-arik.",
        "Masukkan nasi, aduk rata.",
        "Beri kecap, garam, lada.",
        "Sajikan hangat."
      ],
      "estimated_minutes": 10,
      "image_url": null
    };
    return AiRecipe.fromJson(mock);
  }

  // ====== GEMINI 2.0 FLASH ======
  Future<AiRecipe> _getFromGemini(String dishName) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
    );

    final body = {
      "contents": [
        {
          "parts": [
            {"text": _buildJsonPrompt(dishName)}
          ]
        }
      ],
      "generationConfig": {
        "response_mime_type": "application/json",
        "temperature": 0.6
      }
    };

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw Exception('Timeout ke Gemini (25s). Cek internet emulator.');
    } catch (e) {
      throw Exception('Gagal konek ke Gemini: $e');
    }

    // Debug status
    // ignore: avoid_print
    print('Gemini status: ${res.statusCode}');

    if (res.statusCode ~/ 100 != 2) {
      final snippet = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
      throw Exception('HTTP ${res.statusCode}: $snippet');
    }

    final map = jsonDecode(res.body);

    // Ambil SEMUA parts.text, join (kadang lebih dari 1 part)
    final parts = (map['candidates']?[0]?['content']?['parts']) as List<dynamic>?;
    final textJoined = (parts ?? [])
        .map((p) => p is Map ? (p['text'] ?? '').toString() : '')
        .where((s) => s.isNotEmpty)
        .join('\n')
        .trim();

    if (textJoined.isEmpty) {
      throw Exception('Respon Gemini kosong / tidak ada candidates[0].content.parts[].text');
    }

    final cleaned = _stripCodeFence(textJoined);

    // debug ringan (potong biar tidak panjang)
    final preview = cleaned.length > 200 ? '${cleaned.substring(0, 200)}...' : cleaned;
    // ignore: avoid_print
    print('Gemini JSON preview: $preview');

    dynamic jsonObj;
    try {
      jsonObj = jsonDecode(cleaned);
    } catch (_) {
      // Coba cari substring JSON yang valid (terkadang ada teks nyasar)
      final extracted = _extractFirstJson(cleaned);
      if (extracted == null) {
        throw Exception('Gagal parse JSON dari Gemini.\nPayload: $preview');
      }
      jsonObj = jsonDecode(extracted);
    }

    return _normalizeAndBuild(jsonObj);
  }

  String _buildJsonPrompt(String dishName) {
    return '''
Buat 1 resep lengkap untuk hidangan: "$dishName".
Balas HANYA dalam format JSON valid dengan schema berikut:

{
  "title": string,
  "ingredients": string[],
  "steps": string[],
  "estimated_minutes": number,
  "image_url": string | null
}

Kaidah:
- Bahan umum dan realistis.
- Langkah singkat, 1–2 kalimat tiap langkah.
- estimated_minutes antara 5–60.
- Jangan ada teks lain di luar JSON.
''';
  }

  /// Hapus ```json ... ``` atau ``` ... ``` bila ada
  String _stripCodeFence(String s) {
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final m = fence.firstMatch(s);
    if (m != null && m.groupCount >= 1) return m.group(1)!.trim();
    return s.trim();
  }

  /// Ambil JSON object/array pertama yang valid dari string panjang
  String? _extractFirstJson(String s) {
    // cari object { ... } atau array [ ... ]
    final obj = RegExp(r'\{[\s\S]*\}');
    final arr = RegExp(r'\[[\s\S]*\]');
    final mo = obj.firstMatch(s);
    final ma = arr.firstMatch(s);
    if (mo == null && ma == null) return null;
    // pilih yang paling awal muncul
    if (mo != null && (ma == null || mo.start < ma.start)) {
      return mo.group(0);
    }
    return ma?.group(0);
  }

  AiRecipe _normalizeAndBuild(dynamic obj) {
    // Terima Map atau List. Jika List, ambil elemen pertama yang Map.
    Map<String, dynamic> toMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
      throw Exception('Format JSON tidak dikenali (bukan object/array berisi object).');
    }

    final m = toMap(obj);

    List<String> toStrings(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return v
          .toString()
          .split(RegExp(r'[\n\r]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final normalized = {
      "title": (m["title"] ?? "Resep").toString(),
      "ingredients": toStrings(m["ingredients"]),
      "steps": toStrings(m["steps"]),
      "estimated_minutes":
          int.tryParse((m["estimated_minutes"] ?? "15").toString()) ?? 15,
      "image_url": m["image_url"]
    };

    return AiRecipe.fromJson(normalized);
  }
}
