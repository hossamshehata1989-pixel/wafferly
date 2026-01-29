// =========================================================
// _MainCategoriesSection
// ده القسم الكبير اللي بيعرض كل الفئات الرئيسية
// يعمل Grid
// يحدد عدد الأعمدة (3)
// يضيف كارت "إضافة مصروف آخر" في الآخر
// يعرف مين الكارت المختار
// هو الحاوية اللي شايلة باقي الكروت
//==========================================================


class _MainCategoryCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _MainCategoryCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: selected ? 5 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              /// زر الخيارات (يتحرك حسب اللغة)
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Icon(Icons.more_vert, size: 18, color: Colors.grey[700]),
              ),

              const SizedBox(height: 4),

              /// اسم الفئة
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 6),

              /// الوصف + الصورة
              Expanded(
                child: Row(
                  children: [
                    /// الصورة (شمال في العربي)
                    const Icon(Icons.directions_car, size: 36, color: Colors.blue),

                    const SizedBox(width: 6),

                    /// النص (يمين في العربي)
                    const Expanded(
                      child: Text(
                        "Daily transportation",
                        textAlign: TextAlign.start,
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              /// الأزرار
              Row(
  children: [
    Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 2),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {},
        child: const Text(
          "Sub",
          style: TextStyle(fontSize: 9),
        ),
      ),
    ),
    const SizedBox(width: 6),
    Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 2),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {},
        child: const Text(
          "Save",
          style: TextStyle(fontSize: 9),
        ),
      ),
    ),
  ],
)



//==========================================================
// _AddMainCategoryCard
// ده الكارت الخاص بالإضافة
//مسؤوليته:
// يظهر علامة ➕
// يكون آخر عنصر في الجريد
// لما نربطه بعدين يفتح إضافة فئة جديدة
//==========================================================

class _AddMainCategoryCard extends StatelessWidget {
  const _AddMainCategoryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Center(
        child: Icon(Icons.add, size: 40, color: Colors.blue),
      ),
    );
  }
}


