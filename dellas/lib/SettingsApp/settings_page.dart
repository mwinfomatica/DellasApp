import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Components/app_font_icons.dart';
import 'package:dellas/Models/ContextoModel.dart';
import 'package:dellas/Services/ConfigAppService.dart';
import 'package:dellas/Services/ContextoServices.dart';
import 'package:dellas/Services/EnderecoGrupoService.dart';
import 'package:dellas/Services/ProdutosDBService.dart';
import 'package:dellas/SettingsApp/settings_appBar.dart';
import 'package:dellas/Shared/Dialog.dart';

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

  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? device;
  BluetoothCharacteristic? cNotify;
  StreamSubscription<List<int>>? sub;
  Timer? temp;

  List<BluetoothDevice> devicesNames = <BluetoothDevice>[];

  void addDeviceToList(BluetoothDevice dev) {
    if (dev != null && dev.name.isNotEmpty && !devicesNames.contains(dev)) {
      devicesNames.add(dev);
      setState(() {});
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
    if (contextoModel != null && contextoModel.leituraExterna) {
      //Monitorando devices conectados
      flutterBlue.connectedDevices
          .asStream()
          .listen((List<BluetoothDevice> devices) {
        for (BluetoothDevice dev in devices) {
          addDeviceToList(dev);
        }
      });

      //Monitorando devices disponíveis
      flutterBlue.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          addDeviceToList(result.device);
        }
      });

      flutterBlue.startScan();
      setState(() {});
    } else {
      devicesNames = <BluetoothDevice>[];
      flutterBlue.stopScan();
      setState(() {});
    }

    return Future<void>.value();
  }

  Future<void> _validaDevicesConectedBlue() {
    //Monitorando devices conectados
    flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice dev in devices) {
        if (dev != null &&
            contextoModel != null &&
            dev.name.isNotEmpty &&
            contextoModel.uuidDevice.isNotEmpty &&
            dev.id.id == contextoModel.uuidDevice) {
          print("Dispositivo encontrado: ${dev.name}, ID: ${dev.id.id}");
          addDeviceToList(dev);
        }
      }
    });

    flutterBlue.startScan();

    setState(() {});

    return Future<void>.value();
  }

  @override
  void initState() {
    getContexto().then((_) {
      _validaDevicesConectedBlue();
    });
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
              contextoModel.descLeituraExterna,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            value: contextoModel.leituraExterna,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.shade200,
            onChanged: (bool value) async {
              await contextoServices.setTipoLeitor(leitorexterno: value);
              await getContexto();
              setState(() {});
              await _monitoringBlue();
            },
            secondary: Icon(
              Icons.qr_code,
              color: contextoModel.leituraExterna ? primaryColor : Colors.red,
            ),
          ),
          // Visibility(
          //   visible: contextoModel.leituraExterna == true,
          //   child: Divider(
          //     color: primaryColor,
          //     height: 1,
          //   ),
          // ),
          if(contextoModel.leituraExterna)
          ...List.generate(devicesNames.length, (index) {
            return ListTile(
              title: Text(devicesNames[index].name.trim().isNotEmpty
                  ? devicesNames[index].name.trim()
                  : devicesNames[index].id.id),
              trailing: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: contextoModel.uuidDevice == devicesNames[index].id.id
                    ? Icon(
                        Icons.bluetooth_connected,
                        color: primaryColor,
                      )
                    : Icon(Icons.bluetooth_disabled_sharp),
              ),
              onTap: () async {
                await flutterBlue.stopScan();
                await contextoServices.setDeviceSelected(
                    nameDevice: devicesNames[index].name,
                    uuidDevice: devicesNames[index].id.id);
                await getContexto();
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
          ListTile(
            leading: const Icon(
              Icons.streetview,
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
              Icons.production_quantity_limits,
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
              value: contextoModel.enderecoGrupo,
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.shade200,
              secondary: Icon(
                Icons.group_work_outlined,
                color: contextoModel.enderecoGrupo ? primaryColor : Colors.red,
              ),
              onChanged: null,
            ),
          ),
          Divider(
            color: primaryColor,
            height: 1,
          ),
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
