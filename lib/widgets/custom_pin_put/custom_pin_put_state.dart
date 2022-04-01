import 'package:flutter/material.dart';
import 'package:paymint/widgets/custom_pin_put/pin_keyboard.dart';

import 'custom_pin_put.dart';

class CustomPinPutState extends State<CustomPinPut>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  TextEditingController _controller;
  FocusNode _focusNode;
  ValueNotifier<String> _textControllerValue;

  int get selectedIndex => _controller.value.text.length;

  @override
  void initState() {
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _textControllerValue = ValueNotifier<String>(_controller.value.text);
    _controller?.addListener(_textChangeListener);
    _focusNode?.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void _textChangeListener() {
    final pin = _controller.value.text;
    if (pin != _textControllerValue.value) {
      try {
        _textControllerValue.value = pin;
      } catch (e) {
        _textControllerValue = ValueNotifier(_controller.value.text);
      }
      if (pin.length == widget.fieldsCount) widget.onSubmit?.call(pin);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();

    _textControllerValue?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.27,
            child: Stack(
              children: <Widget>[
                _hiddenTextField,
                _fields,
              ],
            ),
          ),
          SizedBox(
            height: 32,
          ),
          PinKeyboard(
            width: MediaQuery.of(context).size.width * 0.667,
            height: MediaQuery.of(context).size.height * 0.45,
            onNumberKeyPressed: (number) => _controller.text += number,
            onBackPressed: () {
              final text = _controller.text;
              if (text.length > 0) {
                _controller.text = text.substring(0, text.length - 1);
              }
            },
          ),
          // Spacer(),
        ],
      ),
    );
  }

  Widget get _hiddenTextField {
    return TextFormField(
      controller: _controller,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      focusNode: _focusNode,
      enabled: widget.enabled,
      enableSuggestions: false,
      autofocus: widget.autofocus,
      readOnly: true,
      obscureText: widget.obscureText != null,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      keyboardAppearance: widget.keyboardAppearance,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      enableInteractiveSelection: false,
      maxLength: widget.fieldsCount,
      showCursor: false,
      scrollPadding: EdgeInsets.zero,
      decoration: widget.inputDecoration,
      style: widget.textStyle != null
          ? widget.textStyle.copyWith(color: Colors.transparent)
          : const TextStyle(color: Colors.transparent),
    );
  }

  Widget get _fields {
    return ValueListenableBuilder<String>(
      valueListenable: _textControllerValue,
      builder: (BuildContext context, value, Widget child) {
        return Row(
          mainAxisSize: widget.mainAxisSize,
          mainAxisAlignment: widget.fieldsAlignment,
          children: _buildFieldsWithSeparator(),
        );
      },
    );
  }

  List<Widget> _buildFieldsWithSeparator() {
    final fields = Iterable<int>.generate(widget.fieldsCount).map((index) {
      return _getField(index);
    }).toList();

    return fields;
  }

  Widget _getField(int index) {
    final String pin = _controller.value.text;
    return AnimatedContainer(
      width: widget.eachFieldWidth,
      height: widget.eachFieldHeight,
      alignment: widget.eachFieldAlignment,
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      padding: widget.eachFieldPadding,
      margin: widget.eachFieldMargin,
      constraints: widget.eachFieldConstraints,
      decoration: _fieldDecoration(index),
      child: AnimatedSwitcher(
        switchInCurve: widget.animationCurve,
        switchOutCurve: widget.animationCurve,
        duration: widget.animationDuration,
        transitionBuilder: (child, animation) {
          return _getTransition(child, animation);
        },
        child: _buildFieldContent(index, pin),
      ),
    );
  }

  Widget _buildFieldContent(int index, String pin) {
    if (index < pin.length) {
      return Text(
        widget.obscureText ?? pin[index],
        key: ValueKey<String>(index < pin.length ? pin[index] : ''),
        style: widget.textStyle,
      );
    }

    return Text(
      '',
      key: ValueKey<String>(index < pin.length ? pin[index] : ''),
      style: widget.textStyle,
    );
  }

  BoxDecoration _fieldDecoration(int index) {
    if (!widget.enabled) return widget.disabledDecoration;
    if (index < selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return widget.submittedFieldDecoration;
    }
    if (index == selectedIndex &&
        (_focusNode.hasFocus || !widget.useNativeKeyboard)) {
      return widget.selectedFieldDecoration;
    }
    return widget.followingFieldDecoration;
  }

  Widget _getTransition(Widget child, Animation animation) {
    switch (widget.pinAnimationType) {
      case PinAnimationType.none:
        return child;
      case PinAnimationType.fade:
        return FadeTransition(
          opacity: animation as Animation<double>,
          child: child,
        );
      case PinAnimationType.scale:
        return ScaleTransition(
          scale: animation as Animation<double>,
          child: child,
        );
      case PinAnimationType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: widget.slideTransitionBeginOffset ?? Offset(0.8, 0),
            end: Offset.zero,
          ).animate(animation as Animation<double>),
          child: child,
        );
      case PinAnimationType.rotation:
        return RotationTransition(
          turns: animation as Animation<double>,
          child: child,
        );
    }
  }
}
