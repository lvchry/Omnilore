import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/model/coordinators.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/theme.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';
import 'package:omnilore_scheduler/widgets/utils.dart';

const List<Color> clusterColors = [
  Color(0xFFB2DFDB), // light green
  Color(0xFFE1BEE7), // light purple
  Color(0xFFFFF9C4), // light yellow
  Color(0xFFD7CCC8), // light brown
  Color(0xFFFFE0B2), // light orange
  Color(0xFFFFF59D), // light amber
  Color(0xFFF8BBD9), // light pink
  Color(0xFFBBDEFB)  // light blue
];

class ClassNameDisplay extends StatefulWidget {
  const ClassNameDisplay(
      {Key? key,
      required this.currentRow,
      required this.currentClass,
      required this.schedule,
      required this.people,
      this.isShowingSplitPreview = false,
      this.tempSplitResult = const {},
      this.currentSplitGroupSelected,
      this.onMovePerson,
      this.onSelectSplitGroup,
      this.onCancelSplitPreview,
      this.coordinatorMode = 'none'})
      : super(key: key);

  final RowType currentRow;
  final String? currentClass;
  final Scheduling schedule;
  final List<String> people;
  final bool isShowingSplitPreview;
  final Map<int, Set<String>> tempSplitResult;
  final int? currentSplitGroupSelected;
  final void Function(String person, int fromGroup, int toGroup)? onMovePerson;
  final void Function(int groupNum)? onSelectSplitGroup;
  final void Function()? onCancelSplitPreview;
  final String coordinatorMode; // 'none', 'main', or 'equal'

  @override
  State<StatefulWidget> createState() => ClassNameDisplayState();
}

class ClassNameDisplayState extends State<ClassNameDisplay> {
  late List<bool> _selected =
      List<bool>.filled(widget.people.length, false, growable: false);
  
  // For coordinator selection mode
  String? _selectedC; // Person selected as C
  String? _selectedCC; // Person selected as CC
  bool _showingCoordinators = false; // Toggle for Show Coords

  void clearSelection() {
    for (int i = 0; i < _selected.length; i++) {
      _selected[i] = false;
    }
    _selectedC = null;
    _selectedCC = null;
  }

  /// Select or deselect a person as C in coordinator mode
  void selectCoordinatorC(String person) {
    setState(() {
      if (_selectedC == person) {
        // Deselect if clicking same person
        _selectedC = null;
      } else {
        _selectedC = person;
      }
    });
  }
  
  /// Select or deselect a person as CC in coordinator mode
  void selectCoordinatorCC(String person) {
    setState(() {
      if (_selectedCC == person) {
        // Deselect if clicking same person
        _selectedCC = null;
      } else {
        _selectedCC = person;
      }
    });
  }
  
  /// Get the selected C coordinator
  String? getSelectedC() => _selectedC;
  
  /// Get the selected CC coordinator
  String? getSelectedCC() => _selectedCC;
  
  /// Clear coordinator selections
  void clearCoordinatorSelections() {
    setState(() {
      _selectedC = null;
      _selectedCC = null;
      _showingCoordinators = false;
    });
  }

  /// Display/hide the coordinators for the current course (toggle)
  void showCoordinators() {
    // don't override any in-progress selection; user should confirm or
    // cancel their current picks before looking at existing assignments.
    if (widget.coordinatorMode != 'none') {
      return;
    }

    setState(() {
      if (_showingCoordinators) {
        // Hide coordinators
        clearCoordinatorSelections();
        _showingCoordinators = false;
      } else {
        // Show coordinators
        Coordinators? coordinator =
            widget.schedule.courseControl.getCoordinators(widget.currentClass!);
        if (coordinator != null) {
          clearCoordinatorSelections();
          if (coordinator.equal) {
            // Equal coordinator mode
            _selectedC = coordinator.coordinators[0];
            if (coordinator.coordinators[1].isNotEmpty) {
              _selectedCC = coordinator.coordinators[1];
            }
          } else {
            // Main/Co coordinator mode
            _selectedC = coordinator.coordinators[0];
            if (coordinator.coordinators[1].isNotEmpty) {
              _selectedCC = coordinator.coordinators[1];
            }
          }
          _showingCoordinators = true;
        }
      }
    });
  }

  /// Set the selected C and CC
  void setMainCoordinator() {
    widget.schedule.courseControl.clearCoordinators(widget.currentClass!);
    if (_selectedC != null) {
      try {
        widget.schedule.courseControl
            .setMainCoCoordinator(widget.currentClass!, _selectedC!);
      } on Exception catch (e) {
        Utils.showPopUp(context, 'Set C/CC error', e.toString());
      }
    }
    if (_selectedCC != null) {
      try {
        widget.schedule.courseControl
            .setMainCoCoordinator(widget.currentClass!, _selectedCC!);
      } on Exception catch (e) {
        Utils.showPopUp(context, 'Set C/CC error', e.toString());
      }
    }
    setState(() {
      clearCoordinatorSelections();
    });
  }

  /// Set the selected CC1 and CC2
  void setCoCoordinator() {
    widget.schedule.courseControl.clearCoordinators(widget.currentClass!);
    if (_selectedC != null) {
      try {
        widget.schedule.courseControl
            .setEqualCoCoordinator(widget.currentClass!, _selectedC!);
      } on Exception catch (e) {
        Utils.showPopUp(context, 'Set CC1/CC2 error', e.toString());
      }
    }
    if (_selectedCC != null) {
      try {
        widget.schedule.courseControl
            .setEqualCoCoordinator(widget.currentClass!, _selectedCC!);
      } on Exception catch (e) {
        Utils.showPopUp(context, 'Set CC1/CC2 error', e.toString());
      }
    }
    setState(() {
      clearCoordinatorSelections();
    });
  }

  @override
  void didUpdateWidget(covariant ClassNameDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = List<bool>.filled(widget.people.length, false, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    // Show split preview if in split preview mode
    if (widget.isShowingSplitPreview && widget.tempSplitResult.isNotEmpty) {
      return _buildSplitPreview();
    }
    
    return Container(
      color: themeColors['MoreBlue'],
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: const Text('CLASS NAMES DISPLAY',
              style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
        ),
        Container(
          alignment: Alignment.center,
          child: const Text('Show constituents by clicking a desired cell.',
              style: TextStyle(fontSize: 15)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: widget.currentRow == RowType.resultingClass ||
                        widget.isShowingSplitPreview
                    ? () {
                        setState(() {
                          for (int i = 0; i < _selected.length; i++) {
                            if (_selected[i]) {
                              widget.schedule.splitControl
                                  .removeCluster(widget.people[i]);
                              _selected[i] = false;
                            }
                          }
                        });
                      }
                    : null,
                child: const Text('Dec Clust')),
            ElevatedButton(
                onPressed: widget.currentRow == RowType.resultingClass ||
                        widget.isShowingSplitPreview
                    ? () {
                        setState(() {
                          Set<String> result = <String>{};
                          for (int i = 0; i < _selected.length; i++) {
                            if (_selected[i]) {
                              result.add(widget.people[i]);
                            }
                          }
                          widget.schedule.splitControl.addCluster(result);
                          clearSelection();
                        });
                      }
                    : null,
                child: const Text('Inc Clust')),
            const ElevatedButton(onPressed: null, child: Text('Back')),
            const ElevatedButton(onPressed: null, child: Text('Forward')),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (widget.currentRow == RowType.unmetWants)
              const Text(
                'Unmet Wants',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              )
            else if (widget.currentRow != RowType.none)
              Text(
                '${_getRowDescription(widget.currentRow)} of ${widget.currentClass}',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              )
          ],
        ),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (int i = 0; i < widget.people.length; i++)
              ElevatedButton(
                  style: (() {
                    String person = widget.people[i];
                    // Coordinator mode colors
                    if (person == _selectedC) {
                      return ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red);
                    }
                    if (person == _selectedCC) {
                      return ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green);
                    }
                    // Regular mode colors
                    if (_selected[i] == true) {
                      return ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red);
                    } else if (widget.isShowingSplitPreview) {
                      return ElevatedButton.styleFrom(
                          backgroundColor: Colors.white);
                    } else {
                      int clusterIndex = widget.schedule.splitControl
                          .getClusterIndex(widget.people[i]);
                      if (clusterIndex == -1) {
                        return ElevatedButton.styleFrom(
                            backgroundColor: Colors.white);
                      } else {
                        return ElevatedButton.styleFrom(
                            backgroundColor: clusterColors[
                                clusterIndex % clusterColors.length]);
                      }
                    }
                  }()),
                  onPressed: widget.currentRow == RowType.resultingClass ||
                          widget.currentRow == RowType.className ||
                          widget.isShowingSplitPreview
                      ? () {
                          String person = widget.people[i];
                          if (widget.currentRow == RowType.className &&
                              widget.coordinatorMode != 'none') {
                            // In coordinator selection mode
                            if (_selectedC == null) {
                              selectCoordinatorC(person);
                            } else if (_selectedCC == null) {
                              selectCoordinatorCC(person);
                            } else if (_selectedC == person) {
                              selectCoordinatorC(person);
                            } else if (_selectedCC == person) {
                              selectCoordinatorCC(person);
                            }
                          } else if (_showingCoordinators &&
                              widget.currentRow == RowType.className &&
                              widget.currentClass != null) {
                            // When coordinators are being shown, tapping one of the
                            // highlighted names should remove the coordinator
                            // assignment entirely.  This gives the user a quick way
                            // to "delete" the current C/CC pair without having to
                            // switch back into selection mode.
                            Coordinators? coords =
                                widget.schedule.courseControl
                                    .getCoordinators(widget.currentClass!);
                            if (coords != null &&
                                (person == coords.coordinators[0] ||
                                    person == coords.coordinators[1])) {
                              widget.schedule.courseControl
                                  .clearCoordinators(widget.currentClass!);
                              setState(() {
                                clearCoordinatorSelections();
                                _showingCoordinators = false;
                              });
                              // early return to avoid running regular mode below
                              return;
                            }
                            // fall through to regular selection if not a coord
                            setState(() {
                              if (widget.currentRow == RowType.resultingClass ||
                                  widget.isShowingSplitPreview) {
                                _selected[i] = !_selected[i];
                              } else {
                                clearSelection();
                                _selected[i] = true;
                              }
                            });
                          } else {
                            // Regular selection mode
                            setState(() {
                              if (widget.currentRow == RowType.resultingClass ||
                                  widget.isShowingSplitPreview) {
                                _selected[i] = !_selected[i];
                              } else {
                                clearSelection();
                                _selected[i] = true;
                              }
                            });
                          }
                        }
                      : null,
                  child: Text(
                    widget.people[i],
                    style: (() {
                      int clusterIndex = widget.schedule.splitControl
                          .getClusterIndex(widget.people[i]);
                      if (clusterIndex != -1 &&
                          clusterColors[clusterIndex % clusterColors.length] ==
                              Colors.brown) {
                        return const TextStyle(color: Colors.white);
                      } else {
                        const TextStyle(color: Colors.black);
                      }
                    }()),
                  ))
          ],
        ),
        Container(
          color: Colors.white,
        )
      ]),
    );
  }

  /// Build the split preview UI
  Widget _buildSplitPreview() {
    List<Widget> wrapChildren = [];
    if (widget.people.isNotEmpty && widget.currentSplitGroupSelected != null) {
      for (String person in widget.people) {
        wrapChildren.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                style: (() {
                  int clusterIndex = widget.schedule.splitControl
                      .getClusterIndex(person);
                  if (clusterIndex == -1) {
                    return ElevatedButton.styleFrom(
                        backgroundColor: Colors.white);
                  } else {
                    return ElevatedButton.styleFrom(
                        backgroundColor: clusterColors[
                            clusterIndex % clusterColors.length]);
                  }
                }()),
                onPressed: () {
                  setState(() {
                    int idx = widget.people.indexOf(person);
                    _selected[idx] = !_selected[idx];
                  });
                },
                child: Text(person,
                    style: const TextStyle(color: Colors.black))),
            if (widget.currentSplitGroupSelected! > 0)
              IconButton(
                  onPressed: () {
                    widget.onMovePerson?.call(
                        person,
                        widget.currentSplitGroupSelected!,
                        widget.currentSplitGroupSelected! - 1);
                  },
                  icon: const Icon(Icons.arrow_left)),
            if (widget.currentSplitGroupSelected! <
                widget.tempSplitResult.length - 1)
              IconButton(
                  onPressed: () {
                    widget.onMovePerson?.call(
                        person,
                        widget.currentSplitGroupSelected!,
                        widget.currentSplitGroupSelected! + 1);
                  },
                  icon: const Icon(Icons.arrow_right)),
          ],
        ));
      }
    }
    return Container(
      color: themeColors['MoreBlue'],
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: const Text('SPLIT PREVIEW',
              style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
        ),
        Container(
          alignment: Alignment.center,
          child: const Text('Select a group and move students between groups',
              style: TextStyle(fontSize: 15)),
        ),
        // Split group selector buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.currentSplitGroupSelected != null &&
                widget.currentSplitGroupSelected! > 0)
              ElevatedButton(
                  onPressed: () {
                    widget.onSelectSplitGroup
                        ?.call(widget.currentSplitGroupSelected! - 1);
                  },
                  child: const Text('← Prev Group')),
            ...List.generate(widget.tempSplitResult.length, (index) {
              bool isSelected =
                  widget.currentSplitGroupSelected == index;
              int groupSize = widget.tempSplitResult[index]?.length ?? 0;
              Set<int> clusters = {};
              for (String person in widget.tempSplitResult[index]!) {
                int ci = widget.schedule.splitControl.getClusterIndex(person);
                if (ci >= 0) clusters.add(ci);
              }
              Color bgColor;
              if (isSelected) {
                bgColor = Colors.blue[700]!;
              } else if (clusters.length == 1) {
                bgColor = clusterColors[clusters.first % clusterColors.length];
              } else {
                bgColor = Colors.white;
              }
              return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: bgColor),
                  onPressed: () {
                    widget.onSelectSplitGroup?.call(index);
                  },
                  child: Text(
                    'Group ${index + 1}\n($groupSize)',
                    style: TextStyle(
                        color: bgColor == Colors.blue[700] ? Colors.white : Colors.black),
                  ));
            }),
            if (widget.currentSplitGroupSelected != null &&
                widget.currentSplitGroupSelected! <
                    widget.tempSplitResult.length - 1)
              ElevatedButton(
                  onPressed: () {
                    widget.onSelectSplitGroup
                        ?.call(widget.currentSplitGroupSelected! + 1);
                  },
                  child: const Text('Next Group →')),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (widget.currentSplitGroupSelected != null)
              Text(
                'Group ${widget.currentSplitGroupSelected! + 1} of ${widget.tempSplitResult.length}',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              )
          ],
        ),
        // Display members of selected group with move buttons
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                wrapChildren.isNotEmpty
                  ? Wrap(
                      direction: Axis.horizontal,
                      children: wrapChildren,
                    )
                  : const Text('No students in this group'),
              ],
            ),
          ),
        ),
        // Cancel button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: widget.onCancelSplitPreview,
                child: const Text('Cancel')),
          ],
        ),
      ]),
    );
  }

  /// Get the description of a row
  String _getRowDescription(RowType row) {
    if (row == RowType.className) {
      return _getRowDescription(RowType.resultingClass);
    }
    if (row == RowType.splitPreview) {
      return 'Split Preview';
    }
    if (row == RowType.unmetWants) {
      return 'Unmet Wants';
    }
    if (row.index - 1 < 0 || row.index - 1 >= overviewRows.length) {
      return '';
    }
    return overviewRows[row.index - 1];
  }
}
