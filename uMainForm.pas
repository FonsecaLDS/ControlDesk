unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Grids, Contnrs, uDeviceModels, uDeviceSimulator, uLogger,
  uNetworkSimulation;

type
  TMainForm = class(TForm)
    FToolbar: TPanel;
    FBtnLoadDemo: TButton;
    FBtnConnect: TButton;
    FBtnDisconnect: TButton;
    FBtnStart: TButton;
    FBtnStop: TButton;
    FBtnExport: TButton;
    FBtnClearLogs: TButton;
    FBtnImportCsv: TButton;
    FBtnTcpSim: TButton;
    FBtnUdpSim: TButton;
    FBtnParsePacket: TButton;
    FBtnDiff: TButton;
    FLeftPanel: TPanel;
    FLeftHeader: TLabel;
    FTree: TTreeView;
    FLeftSplitter: TSplitter;
    FRightPanel: TPanel;
    FRightHeader: TLabel;
    FIndicatorPanel: TPanel;
    FIndicatorLabel: TLabel;
    FDetailLabel0: TLabel;
    FDetailLabel1: TLabel;
    FDetailLabel2: TLabel;
    FDetailLabel3: TLabel;
    FDetailLabel4: TLabel;
    FDetailLabel5: TLabel;
    FDetailLabel6: TLabel;
    FDetailLabel7: TLabel;
    FRightSplitter: TSplitter;
    FCenterPanel: TPanel;
    FPageControl: TPageControl;
    FDataTab: TTabSheet;
    FDataHeader: TLabel;
    FGrid: TStringGrid;
    FDiagnosticsPanel: TPanel;
    FDiagnosticsHeader: TLabel;
    FDiagnosticLabel0: TLabel;
    FDiagnosticLabel1: TLabel;
    FDiagnosticLabel2: TLabel;
    FDiagnosticLabel3: TLabel;
    FDiagnosticLabel4: TLabel;
    FDiagnosticLabel5: TLabel;
    FDiagnosticLabel6: TLabel;
    FDiagnosticLabel7: TLabel;
    FDiagramTab: TTabSheet;
    FDiagramBox: TPaintBox;
    FDiffMemo: TMemo;
    FLogPanel: TPanel;
    FLogMemo: TMemo;
    FStatusBar: TStatusBar;
    FTimer: TTimer;
    FSaveDialog: TSaveDialog;
    FOpenDialog: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnLoadDemoClick(Sender: TObject);
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnDisconnectClick(Sender: TObject);
    procedure BtnStartClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnClearLogsClick(Sender: TObject);
    procedure BtnImportCsvClick(Sender: TObject);
    procedure BtnTcpSimClick(Sender: TObject);
    procedure BtnUdpSimClick(Sender: TObject);
    procedure BtnParsePacketClick(Sender: TObject);
    procedure BtnDiffClick(Sender: TObject);
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure SimulationTimer(Sender: TObject);
    procedure DiagramPaint(Sender: TObject);
  private
    FDevices: TObjectList;
    FSimulator: TDeviceSimulator;
    FNetworkSimulation: TNetworkSimulation;
    FSelectedDevice: TDevice;
    FDetailLabels: array[0..7] of TLabel;
    FDiagnosticLabels: array[0..7] of TLabel;
    procedure AddLog(ALevel: TLogLevel; const AMessage: string);
    procedure BuildLayout;
    procedure LoadDemoData;
    procedure PopulateGrid;
    procedure PopulateTree;
    procedure SelectDevice(ADevice: TDevice);
    procedure UpdateButtonStates;
    procedure UpdateDetails;
    procedure UpdateDiagnostics(const ADiagnostics: TDiagnosticValues);
    procedure UpdateStatusIndicator(AStatus: TDeviceStatus);
    procedure ExportReport(const AFileName: string);
    procedure RefreshDiagram;
    function CurrentDiagnosticsText: TStringList;
  public
  end;

var
  MainForm: TMainForm;

implementation

uses
  uConfigDiff, uCsvDevices, uProtocolPackets;

{$R *.lfm}

const
  GridHeaders: array[0..9] of string = (
    'Item ID', 'Device Name', 'Type', 'Location', 'Protocol', 'Address',
    'Status', 'Firmware Version', 'Last Seen', 'Error Count');

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FDevices := TObjectList.Create(True);
  FSimulator := TDeviceSimulator.Create;
  FNetworkSimulation := TNetworkSimulation.Create;
  BuildLayout;
  LoadDemoData;
  UpdateButtonStates;
  AddLog(llInfo, 'ControlDesk initialized');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FTimer.Enabled := False;
  FNetworkSimulation.Free;
  FSimulator.Free;
  FDevices.Free;
end;

procedure TMainForm.BuildLayout;
var
  I: Integer;
begin
  FDetailLabels[0] := FDetailLabel0;
  FDetailLabels[1] := FDetailLabel1;
  FDetailLabels[2] := FDetailLabel2;
  FDetailLabels[3] := FDetailLabel3;
  FDetailLabels[4] := FDetailLabel4;
  FDetailLabels[5] := FDetailLabel5;
  FDetailLabels[6] := FDetailLabel6;
  FDetailLabels[7] := FDetailLabel7;

  FDiagnosticLabels[0] := FDiagnosticLabel0;
  FDiagnosticLabels[1] := FDiagnosticLabel1;
  FDiagnosticLabels[2] := FDiagnosticLabel2;
  FDiagnosticLabels[3] := FDiagnosticLabel3;
  FDiagnosticLabels[4] := FDiagnosticLabel4;
  FDiagnosticLabels[5] := FDiagnosticLabel5;
  FDiagnosticLabels[6] := FDiagnosticLabel6;
  FDiagnosticLabels[7] := FDiagnosticLabel7;

  for I := 0 to High(GridHeaders) do
    FGrid.Cells[I, 0] := GridHeaders[I];
  FGrid.ColWidths[0] := 82;
  FGrid.ColWidths[1] := 160;
  FGrid.ColWidths[2] := 130;
  FGrid.ColWidths[3] := 100;
  FGrid.ColWidths[4] := 92;
  FGrid.ColWidths[5] := 76;
  FGrid.ColWidths[6] := 74;
  FGrid.ColWidths[7] := 110;
  FGrid.ColWidths[8] := 120;
  FGrid.ColWidths[9] := 82;

  FTimer.OnTimer := @SimulationTimer;
  FDiagramBox.OnPaint := @DiagramPaint;
  FTree.OnChange := @TreeChange;

  FBtnLoadDemo.OnClick := @BtnLoadDemoClick;
  FBtnConnect.OnClick := @BtnConnectClick;
  FBtnDisconnect.OnClick := @BtnDisconnectClick;
  FBtnStart.OnClick := @BtnStartClick;
  FBtnStop.OnClick := @BtnStopClick;
  FBtnExport.OnClick := @BtnExportClick;
  FBtnClearLogs.OnClick := @BtnClearLogsClick;
  FBtnImportCsv.OnClick := @BtnImportCsvClick;
  FBtnTcpSim.OnClick := @BtnTcpSimClick;
  FBtnUdpSim.OnClick := @BtnUdpSimClick;
  FBtnParsePacket.OnClick := @BtnParsePacketClick;
  FBtnDiff.OnClick := @BtnDiffClick;

  FSaveDialog.Title := 'Export ControlDesk Report';
  FSaveDialog.DefaultExt := 'txt';
  FSaveDialog.Filter := 'Text report (*.txt)|*.txt';
end;

procedure TMainForm.LoadDemoData;
begin
  LoadDemoDevices(FDevices);
  FSelectedDevice := nil;
  PopulateTree;
  PopulateGrid;
  RefreshDiagram;
  if FDevices.Count > 0 then
    SelectDevice(TDevice(FDevices[0]));
  AddLog(llInfo, 'Demo data loaded');
end;

procedure TMainForm.PopulateGrid;
var
  I: Integer;
  Device: TDevice;
begin
  FGrid.RowCount := FDevices.Count + 1;
  for I := 0 to FDevices.Count - 1 do
  begin
    Device := TDevice(FDevices[I]);
    FGrid.Cells[0, I + 1] := Device.ItemID;
    FGrid.Cells[1, I + 1] := Device.DeviceName;
    FGrid.Cells[2, I + 1] := Device.DeviceType;
    FGrid.Cells[3, I + 1] := Device.Location;
    FGrid.Cells[4, I + 1] := Device.Protocol;
    FGrid.Cells[5, I + 1] := Device.Address;
    FGrid.Cells[6, I + 1] := DeviceStatusToText(Device.Status);
    FGrid.Cells[7, I + 1] := Device.FirmwareVersion;
    FGrid.Cells[8, I + 1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', Device.LastSeen);
    FGrid.Cells[9, I + 1] := IntToStr(Device.ErrorCount);
  end;
end;

procedure TMainForm.PopulateTree;
var
  Root, BridgeNode, AlarmNode, EngineNode, ParentNode: TTreeNode;
  I: Integer;
  Device: TDevice;
begin
  FTree.Items.BeginUpdate;
  try
    FTree.Items.Clear;
    Root := FTree.Items.Add(nil, 'Vessel System');
    BridgeNode := FTree.Items.AddChild(Root, 'Bridge');
    AlarmNode := FTree.Items.AddChild(Root, 'Alarm System');
    EngineNode := FTree.Items.AddChild(Root, 'Engine Room');

    for I := 0 to FDevices.Count - 1 do
    begin
      Device := TDevice(FDevices[I]);
      ParentNode := Root;
      if Device.Location = 'Bridge' then
        ParentNode := BridgeNode
      else if Device.Location = 'Alarm System' then
        ParentNode := AlarmNode
      else if Device.Location = 'Engine Room' then
        ParentNode := EngineNode;
      FTree.Items.AddChildObject(ParentNode, Device.DeviceName, Device);
    end;

    Root.Expand(True);
  finally
    FTree.Items.EndUpdate;
  end;
end;

procedure TMainForm.SelectDevice(ADevice: TDevice);
begin
  FSelectedDevice := ADevice;
  UpdateDetails;
  PopulateGrid;
end;

procedure TMainForm.UpdateButtonStates;
var
  State: TApplicationState;
begin
  State := FSimulator.State;
  FBtnConnect.Enabled := (State = appDisconnected) or (State = appError);
  FBtnDisconnect.Enabled := State in [appConnected, appSimulating, appError];
  FBtnStart.Enabled := State = appConnected;
  FBtnStop.Enabled := State = appSimulating;
  FBtnExport.Enabled := FDevices.Count > 0;
  FBtnImportCsv.Enabled := State <> appSimulating;
  FStatusBar.SimpleText := 'State: ' + ApplicationStateToText(State) +
    ' | Network: ' + NetworkSimulationModeToText(FNetworkSimulation.Mode);
end;

procedure TMainForm.UpdateDetails;
begin
  if FSelectedDevice = nil then
  begin
    UpdateStatusIndicator(dsOffline);
    Exit;
  end;

  FDetailLabels[0].Caption := 'Device name: ' + FSelectedDevice.DeviceName;
  FDetailLabels[1].Caption := 'Model: ' + FSelectedDevice.Model;
  FDetailLabels[2].Caption := 'Location: ' + FSelectedDevice.Location;
  FDetailLabels[3].Caption := 'Protocol: ' + FSelectedDevice.Protocol;
  FDetailLabels[4].Caption := 'Address: ' + FSelectedDevice.Address;
  FDetailLabels[5].Caption := 'Firmware: ' + FSelectedDevice.FirmwareVersion;
  FDetailLabels[6].Caption := 'Status: ' + DeviceStatusToText(FSelectedDevice.Status);
  FDetailLabels[7].Caption := 'Notes: ' + FSelectedDevice.Notes;
  UpdateStatusIndicator(FSelectedDevice.Status);
end;

procedure TMainForm.UpdateDiagnostics(const ADiagnostics: TDiagnosticValues);
begin
  FDiagnosticLabels[0].Caption := Format('Temperature: %.1f C', [ADiagnostics.Temperature]);
  FDiagnosticLabels[1].Caption := Format('RPM: %d', [ADiagnostics.RPM]);
  FDiagnosticLabels[2].Caption := Format('Voltage: %.1f V', [ADiagnostics.Voltage]);
  FDiagnosticLabels[3].Caption := Format('Current: %.1f A', [ADiagnostics.Current]);
  FDiagnosticLabels[4].Caption := Format('Signal Quality: %d %%', [ADiagnostics.SignalQuality]);
  FDiagnosticLabels[5].Caption := Format('Packet Loss: %.1f %%', [ADiagnostics.PacketLoss]);
  FDiagnosticLabels[6].Caption := 'Alarm State: ' + AlarmStateToText(ADiagnostics.AlarmState);
  FDiagnosticLabels[7].Caption := 'Last Packet Time: ' + FormatDateTime('hh:nn:ss', ADiagnostics.LastPacketTime);
end;

procedure TMainForm.UpdateStatusIndicator(AStatus: TDeviceStatus);
begin
  FIndicatorLabel.Caption := DeviceStatusToText(AStatus);
  case AStatus of
    dsOnline: FIndicatorPanel.Color := clGreen;
    dsOffline: FIndicatorPanel.Color := clGray;
    dsWarning: FIndicatorPanel.Color := clYellow;
    dsError: FIndicatorPanel.Color := clRed;
  end;
  FIndicatorLabel.Font.Color := clBlack;
end;

procedure TMainForm.AddLog(ALevel: TLogLevel; const AMessage: string);
begin
  FLogMemo.Lines.Add(FormatLogLine(ALevel, AMessage));
  FLogMemo.SelStart := Length(FLogMemo.Text);
  FLogMemo.SelLength := 0;
end;

procedure TMainForm.BtnLoadDemoClick(Sender: TObject);
begin
  LoadDemoData;
end;

procedure TMainForm.BtnConnectClick(Sender: TObject);
begin
  try
    FSimulator.Connect;
    AddLog(llInfo, 'Connected to simulated device network');
  except
    on E: Exception do
    begin
      FSimulator.MarkError;
      AddLog(llError, E.Message);
      MessageDlg('Connection error', E.Message, mtError, [mbOK], 0);
    end;
  end;
  UpdateButtonStates;
end;

procedure TMainForm.BtnDisconnectClick(Sender: TObject);
begin
  try
    FTimer.Enabled := False;
    FNetworkSimulation.Stop;
    FSimulator.Disconnect;
    AddLog(llInfo, 'Disconnected from simulated device network');
  except
    on E: Exception do
    begin
      FSimulator.MarkError;
      AddLog(llError, E.Message);
      MessageDlg('Disconnect error', E.Message, mtError, [mbOK], 0);
    end;
  end;
  UpdateButtonStates;
end;

procedure TMainForm.BtnStartClick(Sender: TObject);
begin
  if FSelectedDevice = nil then
  begin
    AddLog(llError, 'Cannot start simulation: no selected device');
    MessageDlg('Simulation', 'Select a device before starting simulation.', mtWarning, [mbOK], 0);
    Exit;
  end;

  try
    FSimulator.StartSimulation;
    FTimer.Enabled := True;
    AddLog(llInfo, 'Simulation started for ' + FSelectedDevice.ItemID);
  except
    on E: Exception do
    begin
      AddLog(llError, E.Message);
      MessageDlg('Simulation error', E.Message, mtError, [mbOK], 0);
    end;
  end;
  UpdateButtonStates;
end;

procedure TMainForm.BtnStopClick(Sender: TObject);
begin
  try
    FTimer.Enabled := False;
    FSimulator.StopSimulation;
    AddLog(llInfo, 'Simulation stopped');
  except
    on E: Exception do
    begin
      AddLog(llError, E.Message);
      MessageDlg('Simulation error', E.Message, mtError, [mbOK], 0);
    end;
  end;
  UpdateButtonStates;
end;

procedure TMainForm.BtnExportClick(Sender: TObject);
begin
  if FSelectedDevice = nil then
  begin
    AddLog(llError, 'Export failed: no selected device');
    MessageDlg('Export report', 'Select a device before exporting a report.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if FSaveDialog.Execute then
  begin
    try
      ExportReport(FSaveDialog.FileName);
      AddLog(llInfo, 'Report exported to ' + FSaveDialog.FileName);
    except
      on E: Exception do
      begin
        AddLog(llError, 'Export failed: ' + E.Message);
        MessageDlg('Export error', E.Message, mtError, [mbOK], 0);
      end;
    end;
  end;
end;

procedure TMainForm.BtnClearLogsClick(Sender: TObject);
begin
  FLogMemo.Clear;
  AddLog(llInfo, 'Logs cleared');
end;

procedure TMainForm.BtnImportCsvClick(Sender: TObject);
var
  MessageText: string;
begin
  if FSimulator.State = appSimulating then
  begin
    AddLog(llWarn, 'CSV import blocked while simulation is running');
    MessageDlg('Import CSV', 'Stop simulation before importing device data.', mtWarning, [mbOK], 0);
    Exit;
  end;

  FOpenDialog.Title := 'Import Device CSV';
  FOpenDialog.Filter := 'CSV files (*.csv)|*.csv|All files (*.*)|*.*';
  if FOpenDialog.Execute then
  begin
    if TCsvDeviceImporter.ImportFromFile(FOpenDialog.FileName, FDevices, MessageText) then
    begin
      FSelectedDevice := nil;
      PopulateTree;
      PopulateGrid;
      RefreshDiagram;
      if FDevices.Count > 0 then
        SelectDevice(TDevice(FDevices[0]));
      AddLog(llInfo, MessageText);
    end
    else
    begin
      AddLog(llError, 'CSV import failed: ' + MessageText);
      MessageDlg('CSV import error', MessageText, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TMainForm.BtnTcpSimClick(Sender: TObject);
begin
  try
    AddLog(llInfo, FNetworkSimulation.StartTcpServerSimulation(15020));
  except
    on E: Exception do
    begin
      AddLog(llError, E.Message);
      MessageDlg('TCP simulation', E.Message, mtError, [mbOK], 0);
    end;
  end;
  UpdateButtonStates;
end;

procedure TMainForm.BtnUdpSimClick(Sender: TObject);
begin
  try
    AddLog(llInfo, FNetworkSimulation.StartUdpBroadcastSimulation('239.10.10.20', 15021));
  except
    on E: Exception do
    begin
      AddLog(llError, E.Message);
      MessageDlg('UDP simulation', E.Message, mtError, [mbOK], 0);
    end;
  end;
  UpdateButtonStates;
end;

procedure TMainForm.BtnParsePacketClick(Sender: TObject);
var
  Packet: string;
  Parsed: TParsedDevicePacket;
begin
  Packet := '';
  if not InputQuery('Parse protocol packet', 'Packet:', Packet) then
    Exit;

  if TProtocolPacketBuilder.TryParseDevicePacket(Packet, Parsed) then
    AddLog(llRx, Format('Parsed %s TEMP=%.1f RPM=%d VOLT=%.1f CURR=%.1f SIGNAL=%d ERR=%d',
      [Parsed.DeviceID, Parsed.Temperature, Parsed.RPM, Parsed.Voltage,
       Parsed.Current, Parsed.SignalQuality, Parsed.ErrorCount]))
  else
  begin
    AddLog(llError, 'Packet parse failed: ' + Parsed.ErrorMessage);
    MessageDlg('Packet parser', Parsed.ErrorMessage, mtWarning, [mbOK], 0);
  end;
end;

procedure TMainForm.BtnDiffClick(Sender: TObject);
var
  OriginalLines, ModifiedLines, DiffLines: TStringList;
  OriginalFile, ModifiedFile: string;
begin
  FOpenDialog.Title := 'Select original configuration';
  FOpenDialog.Filter := 'Text files (*.txt;*.cfg;*.ini)|*.txt;*.cfg;*.ini|All files (*.*)|*.*';
  if not FOpenDialog.Execute then
    Exit;
  OriginalFile := FOpenDialog.FileName;

  FOpenDialog.Title := 'Select modified configuration';
  if not FOpenDialog.Execute then
    Exit;
  ModifiedFile := FOpenDialog.FileName;

  OriginalLines := TStringList.Create;
  ModifiedLines := TStringList.Create;
  DiffLines := TStringList.Create;
  try
    OriginalLines.LoadFromFile(OriginalFile);
    ModifiedLines.LoadFromFile(ModifiedFile);
    TConfigDiffTool.BuildLineDiff(OriginalLines, ModifiedLines, DiffLines);
    FDiffMemo.Lines.Assign(DiffLines);
    FPageControl.ActivePage := FDiagramTab;
    AddLog(llInfo, 'Configuration diff generated');
  except
    on E: Exception do
    begin
      AddLog(llError, 'Configuration diff failed: ' + E.Message);
      MessageDlg('Configuration diff error', E.Message, mtError, [mbOK], 0);
    end;
  end;
  DiffLines.Free;
  ModifiedLines.Free;
  OriginalLines.Free;
end;

procedure TMainForm.TreeChange(Sender: TObject; Node: TTreeNode);
begin
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    SelectDevice(TDevice(Node.Data));
    AddLog(llInfo, 'Selected device ' + FSelectedDevice.ItemID);
  end;
end;

procedure TMainForm.SimulationTimer(Sender: TObject);
var
  Diagnostics: TDiagnosticValues;
  Packet: string;
begin
  try
    Diagnostics := FSimulator.GenerateDiagnostics(FSelectedDevice);
    UpdateDiagnostics(Diagnostics);
    PopulateGrid;
    RefreshDiagram;
    Packet := TProtocolPacketBuilder.BuildDevicePacket(FSelectedDevice.ItemID,
      Diagnostics, FSelectedDevice.ErrorCount);
    AddLog(llTx, FNetworkSimulation.BuildTransmitLog(Packet));
    AddLog(llRx, 'ACK');
    if Diagnostics.PacketLoss > 6.5 then
      AddLog(llWarn, 'Packet loss above threshold');
    if Random(25) = 0 then
      AddLog(llError, 'Device timeout simulated');
  except
    on E: Exception do
    begin
      FTimer.Enabled := False;
      FSimulator.MarkError;
      AddLog(llError, E.Message);
      MessageDlg('Simulation error', E.Message, mtError, [mbOK], 0);
      UpdateButtonStates;
    end;
  end;
end;

procedure TMainForm.DiagramPaint(Sender: TObject);
var
  PaintCanvas: TCanvas;

  procedure DrawBox(const ACaption: string; X, Y, W, H: Integer; AColor: TColor);
  begin
    PaintCanvas.Brush.Color := AColor;
    PaintCanvas.Pen.Color := clGray;
    PaintCanvas.Rectangle(X, Y, X + W, Y + H);
    PaintCanvas.Brush.Style := bsClear;
    PaintCanvas.Font.Style := [fsBold];
    PaintCanvas.TextOut(X + 8, Y + 8, ACaption);
    PaintCanvas.Brush.Style := bsSolid;
    PaintCanvas.Font.Style := [];
  end;

  procedure DrawDevice(ADevice: TDevice; X, Y: Integer);
  var
    Color: TColor;
  begin
    Color := clWhite;
    case ADevice.Status of
      dsOnline: Color := $D9F2D9;
      dsOffline: Color := $E0E0E0;
      dsWarning: Color := $C8FFFF;
      dsError: Color := $C8C8FF;
    end;
    DrawBox(ADevice.DeviceName, X, Y, 170, 34, Color);
    PaintCanvas.TextOut(X + 8, Y + 21, ADevice.Protocol + ' / ' + ADevice.Address);
  end;

var
  I, BridgeY, AlarmY, EngineY: Integer;
  Device: TDevice;
begin
  PaintCanvas := FDiagramBox.Canvas;
  PaintCanvas.Brush.Color := clWhite;
  PaintCanvas.FillRect(FDiagramBox.ClientRect);
  PaintCanvas.Font.Name := 'Segoe UI';
  PaintCanvas.Font.Size := 9;

  DrawBox('Vessel System', 24, 18, 180, 42, $F0F0F0);
  DrawBox('Bridge', 260, 18, 170, 36, $E8F0FF);
  DrawBox('Alarm System', 260, 112, 170, 36, $E8F0FF);
  DrawBox('Engine Room', 260, 206, 170, 36, $E8F0FF);

  PaintCanvas.Pen.Color := clGray;
  PaintCanvas.Line(204, 39, 260, 36);
  PaintCanvas.Line(204, 39, 260, 130);
  PaintCanvas.Line(204, 39, 260, 224);

  BridgeY := 18;
  AlarmY := 112;
  EngineY := 206;
  for I := 0 to FDevices.Count - 1 do
  begin
    Device := TDevice(FDevices[I]);
    if Device.Location = 'Bridge' then
    begin
      DrawDevice(Device, 485, BridgeY);
      Inc(BridgeY, 42);
    end
    else if Device.Location = 'Alarm System' then
    begin
      DrawDevice(Device, 485, AlarmY);
      Inc(AlarmY, 42);
    end
    else if Device.Location = 'Engine Room' then
    begin
      DrawDevice(Device, 485, EngineY);
      Inc(EngineY, 42);
    end;
  end;
end;

procedure TMainForm.RefreshDiagram;
begin
  if FDiagramBox <> nil then
    FDiagramBox.Invalidate;
end;

function TMainForm.CurrentDiagnosticsText: TStringList;
var
  Diagnostics: TDiagnosticValues;
begin
  Result := TStringList.Create;
  Diagnostics := FSimulator.Diagnostics;
  Result.Add(Format('Temperature: %.1f C', [Diagnostics.Temperature]));
  Result.Add(Format('RPM: %d', [Diagnostics.RPM]));
  Result.Add(Format('Voltage: %.1f V', [Diagnostics.Voltage]));
  Result.Add(Format('Current: %.1f A', [Diagnostics.Current]));
  Result.Add(Format('Signal Quality: %d %%', [Diagnostics.SignalQuality]));
  Result.Add(Format('Packet Loss: %.1f %%', [Diagnostics.PacketLoss]));
  Result.Add('Alarm State: ' + AlarmStateToText(Diagnostics.AlarmState));
  if Diagnostics.LastPacketTime > 0 then
    Result.Add('Last Packet Time: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Diagnostics.LastPacketTime))
  else
    Result.Add('Last Packet Time: --');
end;

procedure TMainForm.ExportReport(const AFileName: string);
var
  Report: TStringList;
  DiagnosticsLines: TStringList;
  I, StartLine: Integer;
begin
  if FSelectedDevice = nil then
    raise Exception.Create('No selected device to export.');

  Report := TStringList.Create;
  DiagnosticsLines := nil;
  try
    Report.Add('ControlDesk Device Report');
    Report.Add('Generated: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    Report.Add('');
    Report.Add('Selected Device');
    Report.Add('Item ID: ' + FSelectedDevice.ItemID);
    Report.Add('Device Name: ' + FSelectedDevice.DeviceName);
    Report.Add('Model: ' + FSelectedDevice.Model);
    Report.Add('Type: ' + FSelectedDevice.DeviceType);
    Report.Add('Location: ' + FSelectedDevice.Location);
    Report.Add('Protocol: ' + FSelectedDevice.Protocol);
    Report.Add('Address: ' + FSelectedDevice.Address);
    Report.Add('Firmware: ' + FSelectedDevice.FirmwareVersion);
    Report.Add('Status: ' + DeviceStatusToText(FSelectedDevice.Status));
    Report.Add('Error Count: ' + IntToStr(FSelectedDevice.ErrorCount));
    Report.Add('Notes: ' + FSelectedDevice.Notes);
    Report.Add('Network Mode: ' + NetworkSimulationModeToText(FNetworkSimulation.Mode));
    Report.Add('');
    Report.Add('Latest Diagnostics');
    DiagnosticsLines := CurrentDiagnosticsText;
    Report.AddStrings(DiagnosticsLines);
    Report.Add('');
    Report.Add('Recent Logs');

    StartLine := FLogMemo.Lines.Count - 40;
    if StartLine < 0 then
      StartLine := 0;
    for I := StartLine to FLogMemo.Lines.Count - 1 do
      Report.Add(FLogMemo.Lines[I]);

    Report.SaveToFile(AFileName);
  finally
    DiagnosticsLines.Free;
    Report.Free;
  end;
end;

end.
