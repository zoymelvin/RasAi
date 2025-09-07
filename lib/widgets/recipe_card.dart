import 'package:flutter/material.dart';
import '../models/ai_recipe.dart';

class RecipeCard extends StatelessWidget {
  final AiRecipe data;
  final VoidCallback onTap;
  const RecipeCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(data.title),
        subtitle: Text('Estimasi: ${data.estMinutes} menit'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
