import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook/src/addons/addon.dart';
import 'package:widgetbook/src/addons/addon_provider.dart';
import 'package:widgetbook/src/addons/device_addon/device_provider.dart';
import 'package:widgetbook/src/addons/device_addon/device_selection_provider.dart';
import 'package:widgetbook/src/addons/device_addon/frame_builders/frame_builder.dart';
import 'package:widgetbook/src/addons/device_addon/frame_provider.dart';
import 'package:widgetbook/src/addons/models/panel_size.dart';
import 'package:widgetbook/src/addons/widgets/addon_option_list.dart';
import 'package:widgetbook/src/navigation/router.dart';
import 'package:widgetbook/widgetbook.dart';

export './device_selection.dart';
export './frame_builders/frame_builders.dart';

class DeviceAddon extends WidgetbookAddOn {
  DeviceAddon({required DeviceSelection data})
      : super(
          icon: const Icon(Icons.phone),
          name: 'frames',
          wrapperBuilder: (context, routerData, child) => _wrapperBuilder(
            context,
            child,
            routerData,
            data,
          ),
          panelSize: PanelSize.large,
          builder: _builder,
          providerBuilder: _providerBuilder,
          selectionCount: _selectionCount,
          getQueryParameter: _getQueryParameter,
        );
}

String _getQueryParameter(BuildContext context) {
  final selectedItems =
      context.read<DeviceSelectionProvider>().value.activeFrameBuilder;

  return selectedItems.name;
}

int _selectionCount(BuildContext context) {
  final devices = context.read<DeviceSelectionProvider>().value.activeDevices;
  return devices.isEmpty ? 1 : devices.length;
}

Widget _builder(BuildContext context) {
  final data = context.watch<DeviceSelectionProvider>().value;
  final frameBuilders = data.frameBuilders;
  final activeFrameBuilder = data.activeFrameBuilder;
  final devices = activeFrameBuilder.devices;
  final selectedDevices = data.activeDevices;

  return Row(
    children: [
      Expanded(
        child: AddonOptionList<FrameBuilder>(
          name: 'Frames',
          options: frameBuilders,
          selectedOptions: {
            activeFrameBuilder,
          },
          builder: (item) => Text(item.name),
          onTap: (item) {
            context.read<DeviceSelectionProvider>().tappedFrameBuilder(item);
            context.read<AddOnProvider>().update();
            navigate(context);
          },
        ),
      ),
      Expanded(
        child: AddonOptionList<Device>(
          name: 'Devices',
          options: devices,
          selectedOptions: selectedDevices,
          builder: (item) => Text(item.name),
          onTap: (item) {
            context.read<DeviceSelectionProvider>().tappedDevice(item);
            context.read<AddOnProvider>().update();
            navigate(context);
          },
        ),
      ),
    ],
  );
}

Widget _wrapperBuilder(
  BuildContext context,
  Widget child,
  Map<String, dynamic> routerData,
  DeviceSelection selection,
) {
  final activeFrameString = routerData['frames'] as String?;
  var activeFrame = selection.activeFrameBuilder;
  if (activeFrameString != null) {
    final mapLocales = {for (var e in selection.frameBuilders) e.name: e};

    if (mapLocales.containsKey(activeFrameString)) {
      activeFrame = mapLocales[activeFrameString]!;
    }
  }

  return ChangeNotifierProvider(
    create: (_) => DeviceSelectionProvider(
      selection.copyWith(
        activeFrameBuilder: activeFrame,
      ),
    ),
    child: child,
  );
}

SingleChildWidget _providerBuilder(
  BuildContext context,
  int index,
) {
  final selection = context.watch<DeviceSelectionProvider>().value;
  final frameBuilder = selection.activeFrameBuilder;
  // TODO there is no check if a framebuilder actually has a device
  // so calling first might cause a problem
  final activeDevice = selection.activeDevices.isEmpty
      ? frameBuilder.devices.first
      : selection.activeDevices.elementAt(index);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        key: ValueKey(frameBuilder),
        create: (context) => FrameProvider(
          frameBuilder,
        ),
      ),
      ChangeNotifierProvider(
        key: ValueKey(activeDevice),
        create: (context) => DeviceProvider(
          activeDevice,
        ),
      ),
    ],
  );
}

extension FrameBuilderExtension on BuildContext {
  /// Creates adjustable parameters for the WidgetbookUseCase
  FrameBuilder get frameBuilder => watch<FrameProvider>().value;
}

extension DeviceExteionsion on BuildContext {
  Device get device => watch<DeviceProvider>().value;
}