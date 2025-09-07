class AiRecipe {
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final int estMinutes;
  final String? imageUrl;

  AiRecipe({
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.estMinutes,
    this.imageUrl,
  });

  factory AiRecipe.fromJson(Map<String, dynamic> j) {
    return AiRecipe(
      title: j['title'] ?? 'Tanpa Judul',
      ingredients: (j['ingredients'] as List).map((e) => e.toString()).toList(),
      steps: (j['steps'] as List).map((e) => e.toString()).toList(),
      estMinutes: (j['estimated_minutes'] ?? 15) as int,
      imageUrl: j['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'ingredients': ingredients,
    'steps': steps,
    'estimated_minutes': estMinutes,
    'image_url': imageUrl,
  };
}
