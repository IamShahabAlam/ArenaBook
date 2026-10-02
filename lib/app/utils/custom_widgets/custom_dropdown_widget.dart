import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:arenabook/app/config/app_size_config.dart';
import 'package:arenabook/app/utils/custom_widgets/common_text.dart';
import 'package:arenabook/app/utils/custom_widgets/gradient_button.dart';


import '../../config/app_border_radius.dart';

/////////////////////////////
////////////////////////////
///////////////////////////
//////////////////////////
/////////////////////////
//////////////////////////////////////////////
////////////////////////
/////////////////////////
//////////////////////////
///////////////////////////
////////////////////////////

class CustomChoiceWidget extends StatefulWidget {
  final String label;
  final String hintText;
  final String? searchHint;
  final List<dynamic> items;
  final dynamic selectedItem;
  final bool? canSearch;
  final void Function(dynamic selectedItem) onItemSelected;
  final String? labelKey;
  final String? groupKey;
  final bool isGrid;
  final int crossAxisCount;
  final double dialogHeight;
  final Widget Function(dynamic item)? customItemBuilder;
  final bool displayAsExpansion; // NEW toggle
  final bool? fieldDecoration2;
  final EdgeInsetsGeometry? contentPadding;
  final Color? borderColor;
  final bool? showBorder;
  final Color? fillColor;
  final Color? iconColor;
  const CustomChoiceWidget({
    super.key,
    required this.label,
    required this.hintText,
    required this.items,
    required this.onItemSelected,
    this.selectedItem,
    this.labelKey,
    this.groupKey,
    this.isGrid = false,
    this.crossAxisCount = 3,
    this.dialogHeight = 400,
    this.customItemBuilder,
    this.displayAsExpansion = false,
    this.fieldDecoration2,
    this.contentPadding,
    this.borderColor,
    this.showBorder = false,
    this.fillColor,
    this.iconColor,
    this.searchHint,
    this.canSearch = true,
  });

  @override
  State<CustomChoiceWidget> createState() => _CustomChoiceWidgetState();
}

class _CustomChoiceWidgetState extends State<CustomChoiceWidget> {
  bool _expanded = false; // track expansion state
  late TextEditingController _searchController;
  late List<dynamic> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = List.from(widget.items);
  }

  String _getItemLabel(dynamic item) {
    if (item is Map && widget.labelKey != null) {
      return item[widget.labelKey]?.toString() ?? '';
    }
    return item.toString();
  }

  Map<String, List<dynamic>> _groupItems(List<dynamic> allItems) {
    if (widget.groupKey == null) return {'': allItems};

    final Map<String, List<dynamic>> grouped = {};
    for (var item in allItems) {
      final key = item is Map && item[widget.groupKey] != null ? item[widget.groupKey].toString() : 'Unknown';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    if (grouped.length <= 1) return {'': allItems};
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  Widget _defaultItem(dynamic item) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Get.theme.colorScheme.tertiary),
        borderRadius: BorderRadius.circular(8),
        color: Get.theme.colorScheme.tertiary.withValues(alpha: 0.4),
      ),
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          _getItemLabel(item),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Get.theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _filterItems(String query, StateSetter setState) {
    setState(() {
      if (query.isNotEmpty) {
        _filteredItems = widget.items.where((item) {
          final label = _getItemLabel(item).toLowerCase();
          return label.contains(query.toLowerCase());
        }).toList();
      } else {
        _filteredItems = List.from(widget.items);
      }
    });
  }

  Widget _buildNoDataWidget(ColorScheme theme) {
    return Center(
      child: Container(
        width: widget.dialogHeight,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: theme.outline, size: 40),
            const SizedBox(height: 10),
            Text(
              'No data found',
              style: TextStyle(color: theme.outline, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Expansion mode content
  Widget _buildExpansionContent(StateSetter setState) {
    final grouped = _groupItems(_filteredItems);
    final theme = Get.theme.colorScheme;

    final content = Column(
      children: [
        // Divider
        if (widget.canSearch!) Divider(thickness: 1, color: theme.outline.withValues(alpha: 0.5)),

        // Search bar (optional)
        if (widget.canSearch!)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint ?? 'Search...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => _filterItems(value, setState), // 🔹 uses local state
            ),
          ),

        // Scrollable grouped content
        _filteredItems.isEmpty
            ? _buildNoDataWidget(theme)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: grouped.entries.map((entry) {
                    final groupTitle = entry.key;
                    final groupItems = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.groupKey != null && groupTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            child: Text(
                              groupTitle,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.onSecondary),
                            ),
                          ),

                        // Items
                        widget.isGrid
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: groupItems.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: widget.crossAxisCount,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final item = groupItems[index];
                                  return GestureDetector(
                                    onTap: () {
                                      widget.onItemSelected(item);
                                      setState(() => _expanded = false);
                                    },
                                    child: widget.customItemBuilder != null ? widget.customItemBuilder!(item) : _defaultItem(item),
                                  );
                                },
                              )
                            : Column(
                                children: groupItems.map((item) {
                                  return GestureDetector(
                                    onTap: () {
                                      widget.onItemSelected(item);
                                      setState(() => _expanded = false);
                                    },
                                    child: widget.customItemBuilder != null ? widget.customItemBuilder!(item) : _defaultItem(item),
                                  );
                                }).toList(),
                              ),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ],
    );

    // 🔹 Only constrain height if dialogHeight > 0
    return widget.dialogHeight > 0 ? SizedBox(height: widget.dialogHeight, child: content) : content;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.theme.colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (widget.displayAsExpansion) {
              setState(() => _expanded = !_expanded);
            } else {
              // fallback to dialog
              _openDialog(context);
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: TextEditingController(text: widget.selectedItem != null ? _getItemLabel(widget.selectedItem) : ''),
              clipBehavior: Clip.hardEdge,
              decoration: widget.fieldDecoration2 == true
                  ? InputDecoration(
                      //  prefixText: prefixText,
                      //  suffixText: suffixText,
                      // prefixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: theme.onPrimary),
                      // suffixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: theme.onPrimary),
                      // prefixIcon: preIcon == null ? null : GestureDetector(onTap: onTapPre, child: preIcon),
                      suffixIcon: Icon(_expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: widget.iconColor),
                      contentPadding: widget.fieldDecoration2 == true
                          ? null
                          : widget.contentPadding ??
                                const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ), // contentpadding ?? const EdgeInsets.only(left: 15, right: 15, top: 5),
                      isDense: true,

                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.circularBorderHigh,
                        borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.circularBorderHigh,
                        borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.circularBorderHigh,
                        borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.circularBorderHigh,
                        borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppBorderRadius.circularBorderHigh,
                        borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
                      ),
                      fillColor: widget.fillColor ?? Colors.transparent,
                      errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
                      // floatingLabelAlignment: FloatingLabelAlignment.start,
                      // floatingLabelBehavior: FloatingLabelBehavior.auto,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: theme.outline),
                      filled: true,
                      // errorText: widget.errorText,
                    )
                  : InputDecoration(
                      labelStyle: TextStyle(color: theme.onPrimary, fontSize: 20),
                      labelText: widget.label,
                      hintText: widget.hintText,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.onPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.onPrimary),
                      ),
                      suffixIcon: Icon(_expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: widget.iconColor),
                      hintStyle: const TextStyle(fontSize: 18),
                    ),
              style: widget.fieldDecoration2 == true ? const TextStyle(fontSize: 13) : null,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInCirc,
          child: _expanded && widget.displayAsExpansion ? _buildExpansionContent(setState) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Keep your existing dialog function
  void _openDialog(BuildContext context) {
    // List<dynamic> filteredItems = List.from(widget.items);
    // final TextEditingController localSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Get.theme.colorScheme;

        return StatefulBuilder(
          builder: (context, setState) {
            final grouped = _groupItems(_filteredItems);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.dialogHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label
                      CommonText(text: widget.label, weight: FontWeight.w500, fontSize: 18, color: theme.onSecondary),
                      const SizedBox(height: 10),

                      // Search Field
                      if (widget.canSearch!)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: widget.searchHint ?? 'Search...',
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (value) => _filterItems(value, setState),
                          ),
                        ),

                      // Scrollable grouped content
                      _filteredItems.isEmpty
                          ? _buildNoDataWidget(theme)
                          : Expanded(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  children: grouped.entries.map((entry) {
                                    final groupTitle = entry.key;
                                    final groupItems = entry.value;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (widget.groupKey != null && groupTitle.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            child: CommonText(text: groupTitle.toTitleCase(), weight: FontWeight.w500, fontSize: 16, color: theme.onSecondary),
                                          ),
                                        widget.isGrid
                                            ? GridView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: groupItems.length,
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: widget.crossAxisCount,
                                                  childAspectRatio: 1.5,
                                                  crossAxisSpacing: 8,
                                                  mainAxisSpacing: 8,
                                                ),
                                                itemBuilder: (context, index) {
                                                  final item = groupItems[index];
                                                  return GestureDetector(
                                                    onTap: () {
                                                      widget.onItemSelected(item);
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: widget.customItemBuilder != null ? widget.customItemBuilder!(item) : _defaultItem(item),
                                                  );
                                                },
                                              )
                                            : Column(
                                                children: groupItems.map((item) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      widget.onItemSelected(item);
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: widget.customItemBuilder != null
                                                        ? widget.customItemBuilder!(item)
                                                        : ListTile(
                                                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                                            title: CommonText(text: _getItemLabel(item)),
                                                          ),
                                                  );
                                                }).toList(),
                                              ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//////////////////////
////////////////////
//////////////////
///multiple selection
//////////////////
///////////////////
////////////////////

class CustomChoiceWidgetMulti extends StatefulWidget {
  final String label;
  final String hintText;
  final String? searchHint;
  final List<dynamic> items;
  final dynamic selectedItem;
  final bool? canSearch;
  final void Function(dynamic selectedItem) onItemSelected;
  final String? labelKey;
  final String? idKey;
  final String? groupKey;
  final bool isGrid;
  final int crossAxisCount;
  final double dialogHeight;
  final Widget Function(dynamic item)? customItemBuilder;
  final bool? fieldDecoration2;
  final EdgeInsetsGeometry? contentPadding;
  final Color? borderColor;
  final bool? showBorder;
  final Color? fillColor;
  final Color? iconColor;
  final bool isMultiSelect;

  const CustomChoiceWidgetMulti({
    super.key,
    required this.label,
    required this.hintText,
    required this.items,
    required this.onItemSelected,
    this.selectedItem,
    this.labelKey,
    this.idKey,
    this.groupKey,
    this.isGrid = false,
    this.crossAxisCount = 3,
    this.dialogHeight = 400,
    this.customItemBuilder,
    this.fieldDecoration2,
    this.contentPadding,
    this.borderColor,
    this.showBorder = false,
    this.fillColor,
    this.iconColor,
    this.searchHint,
    this.canSearch = true,
    this.isMultiSelect = false,
  });

  @override
  State<CustomChoiceWidgetMulti> createState() => _CustomChoiceWidgetMultiState();
}

class _CustomChoiceWidgetMultiState extends State<CustomChoiceWidgetMulti> {
  late TextEditingController _searchController;
  late List<dynamic> _filteredItems;
  late List<dynamic> _selectedItems;
  dynamic _selectedItem;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = List.from(widget.items);

    if (widget.isMultiSelect) {
      _selectedItems = widget.selectedItem is List ? List.from(widget.selectedItem) : [];
    } else {
      _selectedItem = widget.selectedItem;
      _selectedItems = [];
    }
  }

  String _getItemLabel(dynamic item) {
    if (item is Map && widget.labelKey != null) {
      return item[widget.labelKey]?.toString() ?? '';
    }
    return item.toString();
  }

  String _getItemId(dynamic item) {
    if (item is Map && widget.idKey != null) {
      return item[widget.idKey]?.toString() ?? '';
    }
    return item.toString();
  }

  void _filterItems(String query, StateSetter setState) {
    setState(() {
      if (query.isNotEmpty) {
        _filteredItems = widget.items.where((item) {
          final label = _getItemLabel(item).toLowerCase();
          return label.contains(query.toLowerCase());
        }).toList();
      } else {
        _filteredItems = List.from(widget.items);
      }
    });
  }

  Map<String, List<dynamic>> _groupItems(List<dynamic> allItems) {
    if (widget.groupKey == null) return {'': allItems};
    final Map<String, List<dynamic>> grouped = {};

    for (var item in allItems) {
      final key = item is Map && item[widget.groupKey] != null ? item[widget.groupKey].toString() : 'Unknown';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  void _toggleSelection(dynamic item, StateSetter setState) {
    if (widget.isMultiSelect) {
      final exists = _selectedItems.any((e) => _getItemId(e) == _getItemId(item));
      if (exists) {
        _selectedItems.removeWhere((e) => _getItemId(e) == _getItemId(item));
      } else {
        _selectedItems.add(item);
      }
      setState(() {});
    } else {
      _selectedItem = item;
      widget.onItemSelected(item);
      Get.back();
    }
  }

  Widget _buildSelectableItem(dynamic item, StateSetter sheetSetState) {
    final theme = Get.theme.colorScheme;

    final isSelected = widget.isMultiSelect
        ? _selectedItems.any((e) => _getItemId(e) == _getItemId(item))
        : _selectedItem != null && _getItemId(_selectedItem) == _getItemId(item);

    return GestureDetector(
      onTap: () => _toggleSelection(item, sheetSetState),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? theme.onPrimary : theme.outline, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? theme.onPrimary.withValues(alpha: 0.08) : null,
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Icon(Icons.monitor_heart_outlined, color: isSelected ? theme.onPrimary : theme.onSecondary, size: 22),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['CounterName'] ?? _getItemLabel(item),
                        style: TextStyle(fontWeight: FontWeight.w500, color: theme.onSecondary, fontSize: 14, overflow: TextOverflow.ellipsis),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      if (item['POSSessionActivityId'] != null)
                        Text(
                          'ID: ${item['POSSessionActivityId']}',
                          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13, color: theme.onSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected) Positioned(right: 0, top: 0, child: Icon(Icons.check_circle, color: theme.onPrimary)),
          ],
        ),
      ),
    );
  }

  void _openDialog(BuildContext context) {
    final theme = Get.theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final grouped = _groupItems(_filteredItems);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _filteredItems = List.from(widget.items);
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  //  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.onSecondary),
                  ),
                  if (widget.canSearch == true)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: widget.searchHint ?? 'Search...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) => _filterItems(value, sheetSetState),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: grouped.entries.map((entry) {
                          final groupTitle = entry.key;
                          final groupItems = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.groupKey != null && groupTitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    groupTitle,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: theme.onSecondary),
                                  ),
                                ),
                              widget.isGrid
                                  ? GridView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: groupItems.length,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: widget.crossAxisCount,
                                        childAspectRatio: 1.5,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemBuilder: (context, i) => _buildSelectableItem(groupItems[i], sheetSetState),
                                    )
                                  : Column(children: groupItems.map((item) => _buildSelectableItem(item, sheetSetState)).toList()),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (widget.isMultiSelect)
                    GradeBtn(
                      circularBorder: 8.0,
                      marginAll: 5.0,
                      name: //"Select",
                      _selectedItems.isEmpty
                          ? "Select"
                          : "Select (${_selectedItems.length})",
                      onpressed: () {
                        final names = _selectedItems.map((e) => _getItemLabel(e)).join(', ');
                        final ids = _selectedItems.map((e) => _getItemId(e)).join(',');
                        widget.onItemSelected({'items': _selectedItems, 'names': names, 'ids': ids});
                        Get.back();
                        _searchController.clear();
                        setState(() {});
                      },
                      firstClr: theme.onPrimary,
                      lastClr: theme.primaryFixed,
                      heightB: 0.065,
                      widthB: 1.0,
                    ).paddingOnly(bottom: 15),

                  // Padding(
                  //   padding: const EdgeInsets.only(top: 8.0),
                  //   child:

                  //   ElevatedButton(
                  //     onPressed: () {
                  //       final names = _selectedItems.map((e) => _getItemLabel(e)).join(', ');
                  //       final ids = _selectedItems.map((e) => _getItemId(e)).join(',');
                  //       widget.onItemSelected({'items': _selectedItems, 'names': names, 'ids': ids});
                  //       Navigator.of(context).pop();
                  //     },
                  //     child: const Text('Select'),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _searchController.clear();
      _filteredItems = List.from(widget.items);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.theme.colorScheme;

    return GestureDetector(
      onTap: () => _openDialog(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: widget.isMultiSelect
                ? _selectedItems.map((e) => _getItemLabel(e)).join(', ')
                : _selectedItem != null
                ? _getItemLabel(_selectedItem)
                : '',
          ),
          decoration: InputDecoration(
            //  prefixText: prefixText,
            //  suffixText: suffixText,
            // prefixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: theme.onPrimary),
            // suffixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: theme.onPrimary),
            // prefixIcon: preIcon == null ? null : GestureDetector(onTap: onTapPre, child: preIcon),
            suffixIcon: Icon(Icons.filter_list, color: widget.iconColor),
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15), // contentpadding ?? const EdgeInsets.only(left: 15, right: 15, top: 5),
            isDense: true,
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circularBorderHigh,
              borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circularBorderHigh,
              borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circularBorderHigh,
              borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circularBorderHigh,
              borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
            ),
            border: OutlineInputBorder(
              borderRadius: AppBorderRadius.circularBorderHigh,
              borderSide: widget.showBorder == false ? BorderSide.none : BorderSide(width: 1, color: widget.borderColor ?? theme.onPrimary),
            ),
            fillColor: widget.fillColor ?? Colors.transparent,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
            // floatingLabelAlignment: FloatingLabelAlignment.start,
            // floatingLabelBehavior: FloatingLabelBehavior.auto,
            hintText: widget.hintText,
            hintStyle: TextStyle(color: theme.outline),
            filled: true,
            // errorText: widget.errorText,
          ),
        ),
      ),
    );
  }
}
