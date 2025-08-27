import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchFilters extends ConsumerStatefulWidget {
  final Function(DateTime? startDate, DateTime? endDate) onFiltersChanged;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const SearchFilters({
    Key? key,
    required this.onFiltersChanged,
    this.initialStartDate,
    this.initialEndDate,
  }) : super(key: key);

  @override
  ConsumerState<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends ConsumerState<SearchFilters> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.filter_list, size: 20),
          SizedBox(width: 8),
          Text('Search Filters'),
        ],
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date Range',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickFilter('Today',
                      () => _setDateRange(DateTime.now(), DateTime.now())),
                  _buildQuickFilter(
                      'Last 7 days',
                      () => _setDateRange(
                          DateTime.now().subtract(Duration(days: 7)),
                          DateTime.now())),
                  _buildQuickFilter(
                      'Last 30 days',
                      () => _setDateRange(
                          DateTime.now().subtract(Duration(days: 30)),
                          DateTime.now())),
                  _buildQuickFilter(
                      'Last 90 days',
                      () => _setDateRange(
                          DateTime.now().subtract(Duration(days: 90)),
                          DateTime.now())),
                  _buildQuickFilter('Clear', () => _clearDateRange()),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Start Date',
                      _startDate,
                      (date) => _setStartDate(date),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'End Date',
                      _endDate,
                      (date) => _setEndDate(date),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilter(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, Function(DateTime?) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: () => _selectDate(date, onDateSelected),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.month}/${date.day}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: date != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(
      DateTime? currentDate, Function(DateTime?) onDateSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      onDateSelected(date);
    }
  }

  void _setDateRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _applyFilters();
  }

  void _setStartDate(DateTime? date) {
    setState(() {
      _startDate = date;
    });
  }

  void _setEndDate(DateTime? date) {
    setState(() {
      _endDate = date;
    });
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  void _applyFilters() {
    widget.onFiltersChanged(_startDate, _endDate);
  }
}
