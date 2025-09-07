import 'package:flutter/material.dart';
import '../models/ai_recipe.dart';

class DetailScreen extends StatelessWidget {
  final AiRecipe recipe;
  const DetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Estimasi: ${recipe.estMinutes} menit',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            const Text('Bahan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...recipe.ingredients.map((e) => Text('• $e')),
            const SizedBox(height: 12),
            const Text('Langkah', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...recipe.steps.asMap().entries.map((e) => Text('${e.key + 1}. ${e.value}')),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // TODO: simpan favorit ke Hive
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ditambahkan ke Favorit (demo)')),
                );
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Simpan ke Favorit'),
            ),
          ],
        ),
      ),
    );
  }
}
