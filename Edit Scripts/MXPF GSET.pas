{
  Gender Based Equipment Tables
  By Isvvc
  Uses MXPF
  praise matortheeternal
}

unit UserScript;

uses 'lib\mxpf';

var
  slLvli, slLvliM, slLvliF: TStringList;
  oftM, oftF: IInterface;

function CheckInEDID(Value: string): Boolean;
begin
  Result := 0;
  // Template:
  //  OR pos('[word]',Value) <> 0
  if pos('Bandit',Value) <> 0 OR pos('Warlock',Value) <> 0 OR pos('Spellsword',Value) <> 0 OR pos('thug',Value) <> 0 OR pos('Dremora',Value) <> 0 OR pos('Necro',Value) <> 0 then
    Result := 1;
end;

function IndexOfStringInArray(Value: string; Strings: TStringList): Integer;
var I: Integer;
begin
  Result := -1;
  for I := 0 to Strings.Count-1 do
    if Strings[i] = Value then begin
      Result := i;
      Exit;
    end;
end;

procedure ProcessLvli;
var
  iindex, oindex, j, k, Level, LastLevel: Integer;
  rec, items, item, li, lvliM, lvliF: IInterface;
begin
  iindex := slLvli.Count -1;
  rec := ObjectToElement(slLvli.Objects[iindex]);
  items := ElementByPath(rec, 'Leveled List Entries');
  k := 0;
  LastLevel := 1;
  for j := 0 to ElementCount(items) - 1 do begin
    li := ElementByIndex(items, j);
    item := LinksTo(ElementByPath(li, 'LVLO - Base Data\Reference'));
    //AddMessage(Name(item));
    //AddMessage(IntToStr(j));
    
    Level := StrToInt(geev(li, 'LVLO - Base Data\Level'));
    if Level > LastLevel then
      k := j;
    LastLevel := Level;
    
    if Signature(item) = 'LVLI' then begin
      //AddMessage(StrToInt(Pos('Male',EditorID(item)) > 0));
      if Pos('Male',EditorID(item)) = false then begin
        oindex := IndexOfStringInArray(Name(item), slLvli);
        if oindex = -1 then begin
          slLvli.AddObject(Name(item),TObject(item));
          lvliM := wbCopyElementToFileWithPrefix(item, mxPatchFile, true, true, '', '', 'Male');
          lvliF := wbCopyElementToFileWithPrefix(item, mxPatchFile, true, true, '', '', 'Female');
          slLvliM.AddObject(Name(lvliM),TObject(lvliM));
          slLvliF.AddObject(Name(lvliF),TObject(lvliF));
          oindex := slLvli.Count -1;
          SetEditValue( ElementByPath(ElementByIndex(ElementByPath(ObjectToElement(slLvliM.Objects[iindex]), 'Leveled List Entries'), k), 'LVLO - Base Data\Reference'), slLvliM[oindex] );
          SetEditValue( ElementByPath(ElementByIndex(ElementByPath(ObjectToElement(slLvliF.Objects[iindex]), 'Leveled List Entries'), k), 'LVLO - Base Data\Reference'), slLvliF[oindex] );
          ProcessLvli;
        end else begin
          SetEditValue( ElementByPath(ElementByIndex(ElementByPath(ObjectToElement(slLvliM.Objects[iindex]), 'Leveled List Entries'), k), 'LVLO - Base Data\Reference'), slLvliM[oindex] );
          SetEditValue( ElementByPath(ElementByIndex(ElementByPath(ObjectToElement(slLvliF.Objects[iindex]), 'Leveled List Entries'), k), 'LVLO - Base Data\Reference'), slLvliF[oindex] );
        end;
        //AddMessage(Name( GetContainer(GetContainer(ElementByPath(ElementByIndex(ElementByPath(ObjectToElement(slLvliM.Objects[iindex]), 'Leveled List Entries'), j), 'LVLO - Base Data\Reference'))) ));
      end;
    end else
      k := k+1;
  end;
end;

function CopyRecordToPatchWithSuffix(i: integer; suffix: string): IInterface;
var
  rec: IInterface;
begin
  // if user hasn't initialized MXPF, raise exception
  if not mxInitialized then
    raise Exception.Create('MXPF Error: You need to call InitialzeMXPF before calling CopyRecordToPatch');
  // if user hasn't loaded records, raise exception
  if not mxLoadCalled then
    raise Exception.Create('MXPF Error: You need to call LoadRecords before you can copy records using CopyRecordToPatch');
  // if user hasn't assigned a patch file, raise exception
  if not Assigned(mxPatchFile) then
    raise Exception.Create('MXPF Error: You need to assign mxPatchFile using PatchFileByAuthor or PatchFileByName before calling CopyRecordToPatch');
  // if no records available, raise exception
  if mxRecords.Count = 0 then
    raise Exception.Create('MXPF Error: Can''t call CopyRecordToPatch, no records available');
  // if index is out of bounds, raise an exception
  if (i < 0) or (i > MaxRecordIndex) then
    raise Exception.Create('MXPF Error: CopyRecordToPatch index out of bounds');
  
  // if all checks pass, try copying record
  rec := ObjectToElement(mxRecords[i]);
    
  // exit if record already exists in patch
  if mxSkipPatchedRecords and OverrideExistsIn(rec, mxPatchFile) then begin
    DebugMessage(Format('Skipping record %s, already in patch!', [Name(rec)]));
    exit;
  end;
  
  // set boolean so we know the user called this function
  mxCopyCalled := true;
  
  // add masters to patch file if we haven't already
  if not mxMastersAdded then AddMastersToPatch;
  
  // copy record to patch
  try
    Result := wbCopyElementToFileWithPrefix(rec, mxPatchFile, true, true, '', '', suffix);
    mxPatchRecords.Add(TObject(Result));
    if mxDebug then DebugMessage(Format('Copied record %s to patch file', [Name(Result)]));
  except on x: Exception do
    FailureMessage(Format('Failed to copy record %s, Exception: %s', [Name(rec), x.Message]));
  end;
end;

function Initialize: Integer;
var
  slFiles, slOutfits, slOutfitsM, slOutfitsF, sMasterFiles: TStringList;
  sFiles: String;
  i, j, k, index: integer;
  rec, item, items, lvliM, lvliF: IInterface;
begin
  {slFiles := TStringList.Create;
  for i := 0 to FileCount - 2 do begin
    slFiles.Add(GetFileName(FileByLoadOrder(i)));
  end;}

  // get file selection from user
  if not MultiFileSelectString('Select the files you want to patch', sFiles) then 
    exit; // if user cancels, exit
    
  { // get file selection from user
  if not MultiFileSelect(slFiles,'Select the files you want to patch') then 
    exit; // if user cancels, exit}
  
  // set up MXPF and load OTFT records from files the user selected
  {InitializeMXPF;
  DefaultOptionsMXPF;

  sMasterFiles := TStringList.Create;
  for i := 0 to mxFiles.Count-1 do begin
    for j := 0 to MasterCount(mxFiles[i])-1 do begin
      sMasterFiles.Add(MasterByIndex(mxFiles[i],j));
    end;
  end;

  mxFileMode := mxInclusionMode;
  mxFiles := sMasterFiles;
  LoadRecords('OTFT');}
  AddMessage('xEdit may appear stop responding while the script is running.');
  AddMessage('Loading outfits...');
  QuickLoad(sFiles, 'OTFT', true);
  
  // initialize stringlist which will hold a list of outfits we find
  slOutfits := TStringList.Create;
  slOutfitsM := TStringList.Create;
  slOutfitsF := TStringList.Create;
  slLvli := TStringList.Create;
  slLvliF := TStringList.Create;
  slLvliM := TStringList.Create;

  PatchFileByAuthor('Isvvc - GSET');
  
  AddMessage('Processing outfits and leveled lists...');
  // add names of outfits to the stringlist
  for i := 0 to MaxRecordIndex do begin
    rec := GetRecord(i);

    if CheckInEDID(geev(rec, 'EDID')) then begin
      slOutfits.Add(Name(rec));
      oftM := CopyRecordToPatchWithSuffix(i, 'Male');
      oftF := CopyRecordToPatchWithSuffix(i, 'Female');
      slOutfitsM.AddObject(Name(oftM), TObject(oftM));
      slOutfitsF.AddObject(Name(oftF), TObject(oftF));

      items := ElementByPath(rec, 'INAM');
      k := 0;
      for j := 0 to ElementCount(items) - 1 do begin
        item := LinksTo(ElementByIndex(items, j));
        //AddMessage(Signature(item)+' '+GetEditValue(ElementByIndex(items, j)));
        if Signature(item) = 'LVLI' then begin
          index := IndexOfStringInArray(Name(item), slLvli);
          if index = -1 then begin
            //AddMessage(Name(item));
            slLvli.AddObject(Name(item),TObject(item));
            lvliM := wbCopyElementToFileWithPrefix(item, mxPatchFile, true, true, '', '', 'Male');
            lvliF := wbCopyElementToFileWithPrefix(item, mxPatchFile, true, true, '', '', 'Female');
            slLvliM.AddObject(Name(lvliM),TObject(lvliM));
            slLvliF.AddObject(Name(lvliF),TObject(lvliF));
            index := slLvli.Count -1;
            SetEditValue( ElementByIndex(ElementByPath(oftM, 'INAM'), k ), slLvliM[index] );
            SetEditValue( ElementByIndex(ElementByPath(oftF, 'INAM'), k ), slLvliF[index] );
            ProcessLvli;
          end else begin
            SetEditValue( ElementByIndex(ElementByPath(oftM, 'INAM'), k ), slLvliM[index] );
            SetEditValue( ElementByIndex(ElementByPath(oftF, 'INAM'), k ), slLvliF[index] );
          end;
          
        end else
          k := k +1;
      end;
    end;
    
  end;

  for i := MaxRecordIndex downto 0 do begin
    RemoveRecord(i);
  end;

  AddMessage('Loading NPCs...');
  SetInclusions(sFiles);
  LoadRecords('NPC_');


  AddMessage('Processing NPCs...');
  for i := 0 to MaxRecordIndex do begin
    rec := GetRecord(i);
    //AddMessage(geev(rec, 'DOFT'));
    if CheckInEDID(geev(rec, 'EDID')) then begin
      if geev(rec, 'DOFT') <> '' then begin
        index := IndexOfStringInArray(Name(LinksTo(ElementByPath(rec, 'DOFT'))), slOutfits);
        if index <> -1 then begin
          if geev(rec, 'ACBS/Flags/Female') = '1' then
            seev(wbCopyElementToFile(rec, mxPatchFile, false, true),'DOFT',slOutfitsF[index])
          else
            seev(wbCopyElementToFile(rec, mxPatchFile, false, true),'DOFT',slOutfitsM[index]);
        end else begin
          AddMessage(Name(rec)+' skipped as outfit was not found');
        end;
      end;
    end;
end;

  // clean up
  FinalizeMXPF;
  //slOutfits.SaveToFile('Outfits.txt');
  //slOutfitsM.SaveToFile('OutfitsMale.txt');
  //slOutfitsF.SaveToFile('OutfitsFemale.txt');
  //AddMessage('Outfits.txt saved.');
  slFiles.Free;
  slOutfits.Free;
  slOutfitsM.Free;
  slOutfitsF.Free;
  slLvli.Free;
  slLvliM.Free;
  slLvliF.Free;
  //sMasterFiles.Free;
end;

end.