package com.souzas.posprinterflutter.posprinter_flutter;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import net.posprinter.posprinterface.IMyBinder;
import net.posprinter.posprinterface.TaskCallback;
import net.posprinter.service.PosprinterService;
import net.posprinter.utils.DataForSendToPrinterZPL;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** PosprinterFlutterPlugin */
public class PosprinterFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private Context context;

  public IMyBinder binder;

  private Handler receiverHandler;
  private HandlerThread thread;

  public static boolean IsConnect = false;

  ServiceConnection mSerConnection = new ServiceConnection() {
    @Override
    public void onServiceConnected(ComponentName componentName, IBinder iBinder) {
      binder = (IMyBinder) iBinder;
      Log.e("myBinder", "connected");
      System.out.println("Service connected");
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
      Log.e("myBinder", "disconnected");
      System.out.println("Service disconnected");
    }
  };

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    Intent serviceIntent = new Intent(context, PosprinterService.class);
    context.bindService(serviceIntent, mSerConnection, Context.BIND_AUTO_CREATE);

    thread = new HandlerThread("receiver");
    thread.start();
    receiverHandler = new Handler(thread.getLooper());

    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "posprinter_flutter");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    System.out.println("Method call at PosprinterFlutterPlugin: " + call.method);

    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("connectBluetooth")) {
      String address = call.argument("address");
      connectBluetooth(result, address);
    } else if (call.method.equals("printSample")) {
      printSample(result);
    } else if (call.method.equals("printText")) {
      final String text = call.argument("text");
      Map<String, Object> optionalParams = call.argument("optionalParams");
      printText(result, text, optionalParams);
    } else if (call.method.equals("printBarCode")) {
      String barCode = call.argument("barCode");
      Map<String, Object> optionalParams = call.argument("optionalParams");
      printBarcode(result, barCode, optionalParams);
    } else if (call.method.equals("printQR")) {
      String qrCode = call.argument("qrCode");
      Map<String, Object> optionalParams = call.argument("optionalParams");
      printQR(result, qrCode, optionalParams);
    } else if (call.method.equals("printBitmap")) {
      printBitmap(result);
    } else if (call.method.equals("printBox")) {
      Map<String, Object> optionalParams = call.argument("optionalParams");
      printBox(result, optionalParams);
    } else {
      result.notImplemented();
    }
  }

  /// This method is used to connect to the bluetooth printer.
  private void connectBluetooth(Result result, String address) {
    binder.ConnectBtPort(address, context, new TaskCallback() {

      @Override
      public void OnSucceed() {
        Log.e("connect", "succeed");
        IsConnect = true;
        result.success("Connected");
      }

      @Override
      public void OnFailed() {
        Log.e("connect", "failed");
        IsConnect = false;
        result.error("Error", "Failed to connect", null);
      }
    }, () -> {
      IsConnect = false;
      result.error("Error", "Disconnected", null);
    });
  }

  /// This method is used to print a sample text.
  private void printSample(Result result) {
    if (IsConnect) {
      binder.WriteSendData(new TaskCallback() {
        @Override
        public void OnSucceed() {
          result.success("Printed");
        }

        @Override
        public void OnFailed() {
          result.error("Error", "Failed to print", null);
        }
      }, () -> {
        List<byte[]> list = new ArrayList<>();
        /// Print start flag
        list.add(DataForSendToPrinterZPL.begin());
        /// Set paper size
        /// For 203dpi printer, 1 inch = 203 dots
        list.add(DataForSendToPrinterZPL.size(800, 1200));
        /// Print direction Normal - N   Invert - I
        list.add(DataForSendToPrinterZPL.direction("I"));
        /// Print position
        list.add(DataForSendToPrinterZPL.align(150, 10));
        /// Print barcode
        list.add(DataForSendToPrinterZPL.barCode("123456", 100));
        /// Print position
        list.add(DataForSendToPrinterZPL.align(150, 130));
        /// Print box
        list.add(DataForSendToPrinterZPL.box(300, 100, 10));
        /// Print position
        list.add(DataForSendToPrinterZPL.align(150, 230));
        /// Print text content
        list.add(DataForSendToPrinterZPL.text("LZHONGHE.TTF", 36, 20, "This is a test text abc"));
        /// Print reverse color text
        /// blackArea() creates a black background area for white text printing output
        list.add(DataForSendToPrinterZPL.align(150, 280));
        list.add(DataForSendToPrinterZPL.blackArea(70,70,3));
        list.add(DataForSendToPrinterZPL.align(250, 280));
        list.add(DataForSendToPrinterZPL.blackArea(70,70,3));
        list.add(DataForSendToPrinterZPL.align(350, 280));
        list.add(DataForSendToPrinterZPL.blackArea(70,70,3));
        list.add(DataForSendToPrinterZPL.align(450, 280));
        list.add(DataForSendToPrinterZPL.blackArea(70,70,3));
        list.add(DataForSendToPrinterZPL.align(150, 280));
        list.add(DataForSendToPrinterZPL.fontCF(0, 70, 70));
        list.add(DataForSendToPrinterZPL.text("REVERSE", true));
        /// Print end flag
        list.add(DataForSendToPrinterZPL.end());
        /// Log.e("Command", encodeHexList(list));
        return list;
      });
    } else {
        result.error("Error", "Error to printSample", null);
    }
  }

  /// This method is used to print a text.
  private void printText(Result result, String text, @Nullable Map<String, Object> optionalParams) {
    if (!IsConnect) {
      result.error("Error", "Printer is not connected", null);
      return;
    }

    binder.WriteSendData(new TaskCallback() {
      @Override
      public void OnSucceed() {
        result.success("Printed");
      }

      @Override
      public void OnFailed() {
        result.error("Error", "Failed to print", null);
      }
    }, () -> {
      List<byte[]> list = new ArrayList<>();
      list.add(DataForSendToPrinterZPL.begin());
      list.add(DataForSendToPrinterZPL.size((int) getOrDefault(optionalParams, "paperWidth", 800), (int) getOrDefault(optionalParams, "paperHeight", 1200)));
      list.add(DataForSendToPrinterZPL.direction((String) getOrDefault(optionalParams, "direction", "N")));
      list.add(DataForSendToPrinterZPL.align((int) getOrDefault(optionalParams, "positionX", 150), (int) getOrDefault(optionalParams, "positionY", 10)));
      list.add(DataForSendToPrinterZPL.text((String) getOrDefault(optionalParams, "font", "LZHONGHE.TTF"), (int) getOrDefault(optionalParams, "fontSize", 36), (int) getOrDefault(optionalParams, "lineSpacing", 20), text));
      list.add(DataForSendToPrinterZPL.end());
      return list;
    });
  }

  /// This method is used to print a barcode.
  private  void printBarcode(Result result, String barcode, @Nullable Map<String, Object> optionalParams) {
    if (!IsConnect) {
      result.error("Error", "Printer is not connected", null);
      return;
    }

    binder.WriteSendData(new TaskCallback() {
      @Override
      public void OnSucceed() {
        result.success("Printed");
      }

      @Override
      public void OnFailed() {
        result.error("Error", "Failed to print", null);
      }
    }, () -> {
      List<byte[]> list = new ArrayList<>();
      list.add(DataForSendToPrinterZPL.begin());
      list.add(DataForSendToPrinterZPL.size((int) getOrDefault(optionalParams, "paperWidth", 800), (int) getOrDefault(optionalParams, "paperHeight", 1200)));
      list.add(DataForSendToPrinterZPL.direction((String) getOrDefault(optionalParams, "direction", "N")));
      list.add(DataForSendToPrinterZPL.align((int) getOrDefault(optionalParams, "positionX", 150), (int) getOrDefault(optionalParams, "positionY", 10)));
      list.add(DataForSendToPrinterZPL.barCodeSize((int) getOrDefault(optionalParams, "barcodeWidth", 2), (int) getOrDefault(optionalParams, "barcodeHeight", 100)));
      list.add(DataForSendToPrinterZPL.barCode(barcode, (int) getOrDefault(optionalParams, "barcodeHeight", 100)));
      list.add(DataForSendToPrinterZPL.end());
      return list;

    });
  }

  /// This method is used to print a QR code.
  private  void printQR(Result result, String qrCode, @Nullable Map<String, Object> optionalParams) {
    if (!IsConnect) {
      result.error("Error", "Printer is not connected", null);
      return;
    }

    binder.WriteSendData(new TaskCallback() {
      @Override
      public void OnSucceed() {
        result.success("Printed");
      }

      @Override
      public void OnFailed() {
        result.error("Error", "Failed to print", null);
      }
    }, () -> {
      List<byte[]> list = new ArrayList<>();
      list.add(DataForSendToPrinterZPL.begin());
      list.add(DataForSendToPrinterZPL.size((int) getOrDefault(optionalParams, "paperWidth", 800), (int) getOrDefault(optionalParams, "paperHeight", 1200)));
      list.add(DataForSendToPrinterZPL.direction((String) getOrDefault(optionalParams, "direction", "N")));
      list.add(DataForSendToPrinterZPL.align((int) getOrDefault(optionalParams, "positionX", 150), (int) getOrDefault(optionalParams, "positionY", 10)));
      list.add(DataForSendToPrinterZPL.qrCode(qrCode));
      list.add(DataForSendToPrinterZPL.end());
      return list;
    });
  }

  /// This method is used to print a bitmap.
  private  void printBitmap(Result result) {
    result.notImplemented();
  }

  /// This method is used to print a box.
  private void printBox(Result result, @Nullable Map<String, Object> optionalParams) {
    if (!IsConnect) {
      result.error("Error", "Printer is not connected", null);
      return;
    }

    binder.WriteSendData(new TaskCallback() {
      @Override
      public void OnSucceed() {
        result.success("Printed");
      }

      @Override
      public void OnFailed() {
        result.error("Error", "Failed to print", null);
      }
    }, () -> {
      List<byte[]> list = new ArrayList<>();
      list.add(DataForSendToPrinterZPL.begin());
      list.add(DataForSendToPrinterZPL.size((int) getOrDefault(optionalParams, "paperWidth", 800), (int) getOrDefault(optionalParams, "paperHeight", 1200)));
      list.add(DataForSendToPrinterZPL.direction((String) getOrDefault(optionalParams, "direction", "N")));
      list.add(DataForSendToPrinterZPL.align((int) getOrDefault(optionalParams, "positionX", 150), (int) getOrDefault(optionalParams, "positionY", 10)));
      list.add(DataForSendToPrinterZPL.box((int) getOrDefault(optionalParams, "width", 300), (int) getOrDefault(optionalParams, "height", 100), (int) getOrDefault(optionalParams, "borderWidth", 10)));
      list.add(DataForSendToPrinterZPL.end());
      return list;
    });
  }

  public static String encodeHexList(List<byte[]> data) {
    StringBuffer sb = new StringBuffer();
    for(byte[] bytes : data){
      for (byte b : bytes) {
        sb.append(String.format("%02x ", b).toUpperCase(Locale.ROOT));
      }
    }
    return sb.toString();
  }

  private Object getOrDefault(Map<String, Object> map, String key, Object defaultValue) {
    if (map != null && map.containsKey(key)) {
      return map.get(key);
    } else {
      return defaultValue;
    }
  }


  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
