import 'dart:async';

import 'package:bluetooth_connector/bluetooth_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/app_font_icons.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ConfigAppService.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/EnderecoGrupoService.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/SettingsApp/settings_appBar.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ContextoServices contextoServices = ContextoServices();

  ContextoModel contextoModel = ContextoModel(
    leituraExterna: false,
    descLeituraExterna: "",
    enderecoGrupo: false,
  );
  bool loadingEnds = false;
  bool loadingProds = false;
  bool noneDevices = true;
  bool collectMode = false;
  bool useCamera = false;

  final FlutterBlue flutterBlue = FlutterBlue.instance;

  BluetoothConnector flutterbluetoothconnector = BluetoothConnector();
  BluetoothDevice? device;
  BluetoothCharacteristic? cNotify;
  StreamSubscription<List<int>>? sub;
  Timer? temp;
  FocusNode myFocusNode = FocusNode();

  List<BtDevice> devicesNames = <BtDevice>[];

  void addDeviceToList(BtDevice dev) {
    if (dev != null && dev.name!.isNotEmpty) {
      var item = devicesNames
          .firstWhere((element) => element.address == dev.address, orElse: () {
        return null as BtDevice;
      });
      if (item == null) {
        devicesNames.add(dev);
        setState(() {});
      }
    }
  }

  Future<void> getContexto() async {
    contextoModel = await contextoServices.getContexto();

    if (contextoModel == null) {
      contextoModel = ContextoModel(leituraExterna: false);
      contextoModel.descLeituraExterna = "Dispositivo Desabilitado";
      contextoModel.enderecoGrupo = false;
    }
    setState(() {});
    await _monitoringBlue();
  }

  Future<void> _monitoringBlue() {
    if (contextoModel != null && contextoModel.leituraExterna!) {
      // logging.FLog.logThis(
      //   text: "Coletando dispositivos pareados ao telefone",
      //   type: logging.LogLevel.SEVERE,
      //   dataLogType: logging.DataLogType.DEVICE.toString(),
      // );

      flutterbluetoothconnector.getDevices().then((List<BtDevice> devices) {
        devices.forEach((BtDevice dev) {
          // logging.FLog.logThis(
          //   text: "Dispositivo ${dev.name} - UUID ${dev.address}",
          //   type: logging.LogLevel.SEVERE,
          //   dataLogType: logging.DataLogType.DEVICE.toString(),
          // );

          addDeviceToList(dev);
        });
      });

      setState(() {});
    } else {
      devicesNames = <BtDevice>[];
      setState(() {});
    }

    return Future<void>.value();
  }

  void _loadSwitchPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      collectMode = prefs.getBool('collectMode') ?? false;
      useCamera = prefs.getBool('useCamera') ?? false;
    });
  }

  void _updateSwitchPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // Desativa os outros switches
    if (value) {
      switch (key) {
        case 'leituraExterna':
          prefs.setBool('collectMode', false);
          prefs.setBool('useCamera', false);
          break;
        case 'collectMode':
          prefs.setBool('leituraExterna', false);
          prefs.setBool('useCamera', false);
          break;
        case 'useCamera':
          prefs.setBool('leituraExterna', false);
          prefs.setBool('collectMode', false);
          break;
      }
    }

    setState(() {
      collectMode = prefs.getBool('collectMode') ?? false;
      useCamera = prefs.getBool('useCamera') ?? false;
    });
  }

  // Future<void> _validaDevicesConectedBlue() {
  //   //Monitorando devices conectados
  //   flutterBlue.connectedDevices
  //       .asStream()
  //       .listen((List<BluetoothDevice> devices) {
  //     for (BluetoothDevice dev in devices) {
  //       if (dev != null &&
  //           contextoModel != null &&
  //           dev.name.isNotEmpty &&
  //           contextoModel.uuidDevice.isNotEmpty &&
  //           dev.id.id == contextoModel.uuidDevice) {
  //         addDeviceToList(dev);
  //       }
  //     }
  //   });

  //   flutterBlue.startScan();

  //   setState(() {});

  //   return Future<void>.value();
  // }

  @override
  void initState() {
    getContexto();
    _loadSwitchPreferences();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120),
        child: AppBarSettings(),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              contextoModel.descLeituraExterna!,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            value: contextoModel.leituraExterna!,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.shade200,
            onChanged: (bool value) async {
              await contextoServices.setTipoLeitor(leitorexterno: value);
              await getContexto();
              setState(() {});
              await _monitoringBlue();
              _updateSwitchPreference('leituraExterna', value);
            },
            secondary: Icon(
              Icons.qr_code,
              color: contextoModel.leituraExterna! ? primaryColor : Colors.red,
            ),
          ),
          Visibility(
            visible: contextoModel.leituraExterna == true,
            child: Divider(
              color: primaryColor,
              height: 1,
            ),
          ),
          if (contextoModel.leituraExterna!)
            ...List.generate(devicesNames.length, (index) {
              return ListTile(
                title: Text(devicesNames[index].name!.trim().isNotEmpty
                    ? devicesNames[index].name!.trim()
                    : devicesNames[index].address!.trim()),
                trailing: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: contextoModel.uuidDevice == devicesNames[index].address
                      ? Icon(
                          Icons.bluetooth_connected,
                          color: primaryColor,
                        )
                      : Icon(Icons.bluetooth_disabled_sharp),
                ),
                onTap: () async {
                  await contextoServices.setDeviceSelected(
                      nameDevice: devicesNames[index].name!,
                      uuidDevice: devicesNames[index].address!);
                  getContexto();
                },
              );
            }),
          Visibility(
            visible: devicesNames.length == 0 &&
                contextoModel.leituraExterna == true,
            child: ListTile(
              leading: Container(
                child: Icon(
                  Icons.warning,
                  color: Colors.red,
                ),
              ),
              title: Text("Nenhum dispositivo encontrado"),
              trailing: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.bluetooth_disabled,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          Divider(
            color: primaryColor,
            height: 1,
          ),
          SwitchListTile(
            title: Text(
              "Usar modo coletor",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            value: collectMode,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.shade200,
            secondary: Icon(
              Icons.install_mobile,
              color: collectMode ? primaryColor : Colors.red,
            ),
            onChanged: (value) {
              setState(() {
                collectMode = value;
                _updateSwitchPreference('collectMode', value);
                if (collectMode) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    myFocusNode.requestFocus();
                  });
                }
              });
            },
          ),

          Visibility(
            visible: collectMode == true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                focusNode: myFocusNode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ),
          Divider(
            color: primaryColor,
            height: 1,
          ),

          SwitchListTile(
            title: Text(
              "Usar Câmera",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            value: useCamera,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.shade200,
            secondary: Icon(
              Icons.camera_alt,
              color: useCamera ? primaryColor : Colors.red,
            ),
            onChanged: (value) {
              setState(() {
                useCamera = value;
                _updateSwitchPreference('useCamera', value);
              });
            },
          ),
          Divider(
            color: primaryColor,
            height: 1,
          ),
          ListTile(
            leading: const Icon(
              MWAppFont.items_reload,
              color: primaryColor,
              size: 25,
            ),
            onTap: () async {
              await _integraEnderecos(context);
            },
            title: Text('Atualizar Endereços'),
            trailing: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: loadingEnds
                  ? Container(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(),
                    )
                  : Icon(
                      Icons.refresh,
                      size: 30,
                    ),
            ),
          ),

          Divider(
            color: primaryColor,
            height: 1,
          ),
          ListTile(
            leading: const Icon(
              MWAppFont.product_reload,
              color: primaryColor,
              size: 25,
            ),
            onTap: () async {
              await _integraProdutos(context);
            },
            title: Text('Atualizar Produtos'),
            trailing: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: 30,
                height: 30,
                child: loadingProds
                    ? Container(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(),
                      )
                    : Icon(
                        Icons.refresh,
                        size: 30,
                      ),
              ),
            ),
          ),
          Divider(
            color: primaryColor,
            height: 1,
          ),
          Opacity(
            opacity: 0.5,
            child: SwitchListTile(
              title: Text(
                "Validação Endereço Grupo",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              value: contextoModel.enderecoGrupo!,
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.shade200,
              secondary: Icon(
                Icons.group_work_outlined,
                color: contextoModel.enderecoGrupo! ? primaryColor : Colors.red,
              ),
              onChanged: null,
            ),
          ),
          Divider(
            color: primaryColor,
            height: 1,
          ),
          // ListTile(
          //   leading: const Icon(
          //     MWAppFont.product_reload,
          //     color: primaryColor,
          //     size: 25,
          //   ),
          //   onTap: () async {
          //     var file = await logging.FLog.exportLogs();
          //     await logging.FLog.clearLogs();

          //     var directory = await getExternalStorageDirectory();

          //     Share.shareFiles(
          //       ['${directory.path}/FLogs/flog.txt'],
          //       text: 'Log',
          //     );
          //     // try {
          //     //   file.copy("/storage/emulated/0/Download/Dellas.txt");
          //     //   Dialogs.showToast(
          //     //       context, "Logs exportados para Download/Dellas.txt",
          //     //       duration: Duration(seconds: 5),
          //     //       bgColor: Colors.green.shade200);
          //     // } catch (e) {
          //     //   Dialogs.showToast(context,
          //     //       "Logs exportados para Android/data/com.mwsoftware.dellas/files/FLogs",
          //     //       duration: Duration(seconds: 5),
          //     //       bgColor: Colors.green.shade200);
          //     // }
          //   },
          //   title: Text('Exportar Logs'),
          //   trailing: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 12),
          //     child: Container(
          //       width: 30,
          //       height: 30,
          //       child: Icon(
          //         Icons.refresh,
          //         size: 30,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _integraEnderecos(BuildContext context) async {
    loadingEnds = true;
    setState(() {});
    final GlobalKey keyloader = new GlobalKey<State>();
    Dialogs.showFreezePageLinearProgress(context, keyloader);

    ConfigAppService configAppService = ConfigAppService();
    await configAppService.saveEnderecosDB();
    EnderecoGrupoService enderecoGrupoService = EnderecoGrupoService();
    await enderecoGrupoService.saveEnderecosGrupoDB();

    Navigator.pop(context);
    loadingEnds = false;
    setState(() {});
    Dialogs.showToast(context, "Endereços atualizados com sucesso",
        duration: Duration(seconds: 5), bgColor: Colors.green.shade200);
  }

  Future<void> _integraProdutos(BuildContext context) async {
    loadingProds = true;
    setState(() {});

    final GlobalKey keyloader = new GlobalKey<State>();
    Dialogs.showFreezePageLinearProgress(context, keyloader);

    ProdutosDBService produtosDBService = ProdutosDBService();
    await produtosDBService.updateProdutosDB();

    Navigator.pop(context);

    loadingProds = false;
    setState(() {});

    Dialogs.showToast(context, "Produtos atualizados com sucesso",
        duration: Duration(seconds: 5), bgColor: Colors.green.shade200);
  }
}
