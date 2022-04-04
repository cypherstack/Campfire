import 'package:flutter/material.dart';

class DraggableSwitchButton extends StatefulWidget {
  const DraggableSwitchButton(
      {Key key,
      this.onItem,
      this.offItem,
      this.onValueChanged,
      this.enabled: true})
      : super(key: key);

  final Widget onItem;
  final Widget offItem;
  final Function(bool) onValueChanged;
  final bool enabled;

  @override
  DraggableSwitchButtonState createState() => DraggableSwitchButtonState();
}

class DraggableSwitchButtonState extends State<DraggableSwitchButton> {
  bool _enabled;
  bool get enabled => _enabled;

  ValueNotifier<double> valueListener = ValueNotifier(0.0);

  @override
  initState() {
    this._enabled = widget.enabled;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _enabled = !_enabled;
        widget.onValueChanged(_enabled);
        valueListener.value = _enabled ? 0.0 : 1.0;
      },
      child: LayoutBuilder(
        builder: (context, constraint) {
          return Stack(
            children: [
              Container(
                height: constraint.maxHeight,
                width: constraint.maxWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(constraint.maxHeight / 2),
                  color: Color(0xFFFFBABE),
                ),
              ),
              Builder(
                builder: (context) {
                  final handle = GestureDetector(
                    key: Key("draggableSwitchButtonSwitch"),
                    onHorizontalDragUpdate: (details) {
                      valueListener.value = (valueListener.value +
                              details.delta.dx / constraint.maxWidth)
                          .clamp(0.0, 1.0);
                    },
                    onHorizontalDragEnd: (details) {
                      bool oldValue = _enabled;
                      if (valueListener.value > 0.5) {
                        valueListener.value = 1.0;
                        _enabled = false;
                      } else {
                        valueListener.value = 0.0;
                        _enabled = true;
                      }
                      if (_enabled != oldValue) {
                        widget.onValueChanged(_enabled);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        height: constraint.maxHeight - 4,
                        width: constraint.maxWidth / 2 - 4,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(constraint.maxHeight / 2),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                  return AnimatedBuilder(
                    animation: valueListener,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(valueListener.value * 2 - 1, 0.5),
                        child: child,
                      );
                    },
                    child: handle,
                  );
                },
              ),
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: constraint.maxWidth / 2,
                      child: Center(
                        child: widget.onItem,
                      ),
                    ),
                    Container(
                      width: constraint.maxWidth / 2,
                      child: Center(
                        child: widget.offItem,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
