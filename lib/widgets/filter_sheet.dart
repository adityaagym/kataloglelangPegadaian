import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class FilterSheet extends StatefulWidget {
  final int? initialCategoryId;
  final Function(int? categoryId, double? minPrice, double? maxPrice) onApply;

  const FilterSheet({super.key, this.initialCategoryId, required this.onApply});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  int? _selectedCategoryId;
  double _minPrice = 0;
  double _maxPrice = 50000000;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Barang Lelang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _selectedCategoryId == null,
                    onSelected: (s) => setState(() => _selectedCategoryId = null),
                  ),
                  ...provider.categories.map((c) => ChoiceChip(
                    label: Text(c.name),
                    selected: _selectedCategoryId == c.id,
                    onSelected: (s) => setState(() => _selectedCategoryId = s ? c.id : null),
                  )).toList(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Rentang Harga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 50000000,
            divisions: 100,
            labels: RangeLabels('Rp ${_minPrice.toInt()}', 'Rp ${_maxPrice.toInt()}'),
            activeColor: const Color(0xFF1B5E20),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _minPrice = 0;
                      _maxPrice = 50000000;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Reset Filter'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                  onPressed: () {
                    widget.onApply(_selectedCategoryId, _minPrice, _maxPrice);
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Terapkan Filter'),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
