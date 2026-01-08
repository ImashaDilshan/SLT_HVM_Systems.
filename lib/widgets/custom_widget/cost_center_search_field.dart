
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slt_hire_log/blocks/CostCenterSearch/cost_center_search_bloc.dart';
import 'package:slt_hire_log/blocks/SharedData/shared_data_state.dart';

class CostCenterSearchField extends StatefulWidget {
   final FocusNode? focusNode;
  final VoidCallback? onOverlayClosed;

  const CostCenterSearchField({
    super.key,
    this.focusNode,
    this.onOverlayClosed,
  });
  @override
  State<CostCenterSearchField> createState() => _SCState();
}

class _SCState extends State<CostCenterSearchField> {
  late FocusNode _focusNode;
  final _controller = TextEditingController();
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  double _fieldWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    widget.onOverlayClosed?.call();
  }

  void _openOverlay(List list) {
  _removeOverlay();

  _overlay = OverlayEntry(
    builder: (_) => Positioned(
      width: _fieldWidth,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        offset: const Offset(0, 48),
        child: Material(
          elevation: 4,
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top overlay bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search Results',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        splashRadius: 16,
                        onPressed: () {
                          _controller.clear();
                          _removeOverlay();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Search list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      return InkWell(
                        onTap: () {
                          context.read<SharedDataCubit>().setLocation(e['cost_center_id'].toString());
                          _removeOverlay();
                          FocusScope.of(context).unfocus();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['cost_center_name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${e['cost_center_id']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(_overlay!);
}

  @override
  Widget build(BuildContext context) {
    return BlocListener<CostCenterSearchBloc, CostCenterSearchState>(
      listener: (_, state) {
        if (state is SearchLoaded) {
          _openOverlay(state.data);
        } else {
          _removeOverlay();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_fieldWidth != constraints.maxWidth) {
              setState(() {
                _fieldWidth = constraints.maxWidth;
              });
              if (_overlay != null) {
                context.read<CostCenterSearchBloc>().add(SearchCostCenter(_controller.text));
              }
            }
          });

          return CompositedTransformTarget(
            link: _link,
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              cursorColor: Colors.blue,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Search cost center',
                labelStyle: const TextStyle(color: Colors.black54),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) {
                context.read<CostCenterSearchBloc>().add(SearchCostCenter(v));
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }
}
