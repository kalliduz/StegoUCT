unit Tree;

interface
uses
  {$IFDEF FPC}
  Classes, Math, Generics.Defaults, Generics.Collections;
  {$ELSE}
  System.Classes, System.Math, System.Generics.Defaults, System.Generics.Collections;
  {$ENDIF}
type
  ICompareableData = interface
  ['{C7B36C09-DFE7-4177-8634-7C865FE7FDB6}']
//    function GetData:T;
    function CompareTo(AObject:TOBject):Integer;
                                         //<0 -> this object is less than other
                                         //=0 -> this object has same value as other
                                         //>0 -> this object has greater value than other
//    procedure FreeData;                  //provide your own free method for your data!

  end;


  TTreeNode<T:ICompareableData> = class(TObject)
  private
    FContent:T;
    FDepth:Integer;
    FParent:TTreeNode<T>;
    FChilds:TList<TTreeNode<T>>;
    function GetChildCount:Int64;
    function GetChildAtIndex(AIndex:Int64):TTreeNode<T>;
  public
    property ChildCount:Int64 read GetChildCount;
    property Childs[Index:Int64]:TTreeNode<T> read GetChildAtIndex;
    property Content:T read FContent;
    property Parent:TTreeNode<T> read FParent;
    property Depth:Integer read FDepth;
    function GetHighestChild(const AExcludeSelf:Boolean = False):TTreeNode<T>;
    function GetHighestDirectChild(const AIncludeSelf:Boolean = True):TTreeNode<T>;
    function CompareTo(ATreeNode:TTreeNode<T>):Integer;
    function AddChild(AData:T):TTreeNode<T>;
    function GetMaxDepth:Int64;
    function NodeCount:Int64;

    constructor Create(AData:T;AParent:TTreeNode<T>);
    destructor Destroy;
  end;

  TTree<T:class,ICompareableData> = class
  private
    FRootNode:TTreeNode<T>;
    FNodeCount:Int64;
    FMemoryUsed:Int64; //in bytes

  public
    constructor Create(ARootNodeData:T);
    function GetHighestNode:TTreeNode<T>;
    function NodeCount:Int64;
    function GetRandomLeaf:TTreeNode<T>;
    property RootNode:TTreeNode<T> read FRootNode;
    destructor Destroy;

  end;

implementation

{$REGION 'TTree implementation'}
function TTree<T>.GetRandomLeaf:TTreeNode<T>;
begin
  Result:=RootNode;
  while True do
  begin
    if Result.ChildCount>0 then
    begin
      Result:=Result.Childs[Random(Result.ChildCount)]; //choose random child as new node
    end
    else
      Exit; //no childs? we found a leaf
  end;
end;
destructor TTree<T>.Destroy;
begin
  FRootNode.Destroy;
  inherited Destroy;
end;
function TTree<T>.NodeCount:Int64;
begin
  Result:=FRootNode.NodeCount;
end;
function TTree<T>.GetHighestNode:TTreeNode<T>;
begin
  Result:=FRootNode.GetHighestChild;
end;

 constructor TTree<T>.Create(ARootNodeData:T);
 begin
   inherited Create;
   FRootNode:=TTreeNode<T>.Create(ARootNodeData,nil);
 end;
 {$ENDREGION}
{$REGION ' TTreeNode Implementation'}
 function TTreeNode<T>.GetMaxDepth:Int64;
 var
  i:Integer;
 begin
   if ChildCount = 0 then
   begin
     Result:=FDepth;
   end else
   begin
      Result:=0;
     for i := 0 to ChildCount-1 do
     begin


      Result:=Max(Result,Childs[i].GetMaxDepth);
     end;
   end;
 end;
 function TTreeNode<T>.NodeCount:Int64;
 var
  i:Integer;
 begin
   Result:=1;
   for i := 0 to ChildCount-1 do
    Result:=Result+Childs[i].NodeCount;
 end;

function TTreeNode<T>.GetHighestDirectChild(const AIncludeSelf:Boolean = True):TTreeNode<T>;
var
  i:Integer;
begin
  Result:=nil;
  if AIncludeSelf then
    Result:=Self;
  for i := 0 to ChildCount-1 do
  begin
    if Result=nil then
      Result:=Childs[i];
    if Result.CompareTo(Childs[i])<0 then
    begin
      Result:=Childs[i];
    end;
  end;
end;
function TTreeNode<T>.GetHighestChild(const AExcludeSelf:Boolean = false):TTreeNode<T>;
var
  i:Integer;
  LTemp:TTreeNode<T>;
begin
  Result:=Self;
  for i := 0 to ChildCount-1 do
  begin
    if AExcludeSelf then if Result  = Self then
    begin
      Result:=Childs[i];
    end;
    LTemp:=Childs[i].GetHighestChild;
    if Result.CompareTo(LTemp)<0 then  //if destination node greater than own
    begin
      Result:=LTemp;
    end;
  end;
end;

destructor TTreeNode<T>.Destroy;
var
  i:Integer;
begin
  for i := 0 to ChildCount-1 do
  begin
    Childs[i].Destroy;
  end;
  PObject(@Content)^.Destroy;
  inherited Destroy;
end;

constructor TTreeNode<T>.Create(AData:T;AParent:TTreeNode<T>);
begin
  inherited Create;
  FContent:=AData;
  FParent:=AParent;
  if AParent = nil then
    FDepth:=0
  else
    FDepth:=AParent.Depth+1;
  FChilds:=TList<TTreeNode<T>>.Create;
end;

  function TTreeNode<T>.CompareTo(ATreeNode:TTreeNode<T>):Integer;
  begin
    Result:= Content.CompareTo(PObject(@ATreeNode.Content)^);
  end;

  function TTreeNode<T>.GetChildAtIndex(AIndex:Int64):TTreeNode<T>;
  begin
    Result:=nil;
    if AIndex<0 then
      Exit;
    if AIndex>=ChildCount then
      Exit;
    Result:= FChilds[AIndex];
  end;

  function TTreeNode<T>.GetChildCount:Int64;
  begin
    Result:= FChilds.Count;
  end;

  function TTreeNode<T>.AddChild(AData:T):TTreeNode<T>;
  var
    LTreeNode:TTreeNode<T>;
  begin

    LTreeNode:=TTreeNode<T>.Create(AData,Self);
    FChilds.Add(LTreeNode);
    Result:=LTreeNode;
  end;
  {$ENDREGION}

end.
