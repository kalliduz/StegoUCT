unit Tree;

interface
uses
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections;
type
  ICompareableData<T> = interface
  ['{C7B36C09-DFE7-4177-8634-7C865FE7FDB6}']
    function GetData:T;
    function CompareTo(AData:T):Integer;
                                         //<0 -> this object is less than other
                                         //=0 -> this object has same value as other
                                         //>0 -> this object has greater value than other
    procedure FreeData;                  //provide your own free method for your data!

  end;


  TTreeNode<D;T:ICompareableData<D>> = class(TObject)
  private
    FContent:T;
    FDepth:Integer;
    FParent:TTreeNode<D,T>;
    FChilds:TList<TTreeNode<D,T>>;
    function GetChildCount:Int64;
    function GetChildAtIndex(AIndex:Int64):TTreeNode<D,T>;
  public
    property ChildCount:Int64 read GetChildCount;
    property Childs[Index:Int64]:TTreeNode<D,T> read GetChildAtIndex;
    property Content:T read FContent;
    property Parent:TTreeNode<D,T> read FParent;
    property Depth:Integer read FDepth;
    function GetHighestChild(const AExcludeSelf:Boolean = False):TTreeNode<D,T>;
    function GetHighestDirectChild(const AIncludeSelf:Boolean = True):TTreeNode<D,T>;
    function CompareTo(ATreeNode:TTreeNode<D,T>):Integer;
    function AddChild(AData:T):TTreeNode<D,T>;
    function NodeCount:Int64;

    constructor Create(AData:T;AParent:TTreeNode<D,T>);
    destructor Destroy;
  end;

  TTree<D;T:ICompareableData<D>> = class
  private
    FRootNode:TTreeNode<D,T>;
    FNodeCount:Int64;
    FMemoryUsed:Int64; //in bytes
    FMaxDepth:Int64;

  public
    constructor Create(ARootNodeData:T);
    function GetHighestNode:TTreeNode<D,T>;
    function NodeCount:Int64;
    function GetRandomLeaf:TTreeNode<D,T>;
    property RootNode:TTreeNode<D,T> read FRootNode;
    destructor Destroy;

  end;

implementation

{$REGION 'TTree implementation'}
function TTree<D,T>.GetRandomLeaf:TTreeNode<D,T>;
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
destructor TTree<D,T>.Destroy;
begin
  FRootNode.Destroy;
  inherited Destroy;
end;
function TTree<D,T>.NodeCount:Int64;
begin
  Result:=FRootNode.NodeCount;
end;
function TTree<D,T>.GetHighestNode:TTreeNode<D,T>;
begin
  Result:=FRootNode.GetHighestChild;
end;

 constructor TTree<D,T>.Create(ARootNodeData:T);
 begin
   inherited Create;
   FRootNode:=TTreeNode<D,T>.Create(ARootNodeData,nil);
 end;
 {$ENDREGION}
{$REGION ' TTreeNode Implementation'}
 function TTreeNode<D,T>.NodeCount:Int64;
 var
  i:Integer;
 begin
   Result:=1;
   for i := 0 to ChildCount-1 do
    Result:=Result+Childs[i].NodeCount;
 end;

function TTreeNode<D,T>.GetHighestDirectChild(const AIncludeSelf:Boolean = True):TTreeNode<D,T>;
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
function TTreeNode<D,T>.GetHighestChild(const AExcludeSelf:Boolean = false):TTreeNode<D,T>;
var
  i:Integer;
  LTemp:TTreeNode<D,T>;
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

destructor TTreeNode<D,T>.Destroy;
var
  i:Integer;
begin
  for i := 0 to ChildCount-1 do
  begin
    Childs[i].Destroy;
  end;
  Content.FreeData;
  inherited Destroy;
end;

constructor TTreeNode<D,T>.Create(AData:T;AParent:TTreeNode<D,T>);
begin
  inherited Create;
  FContent:=AData;
  FParent:=AParent;
  if AParent = nil then
    FDepth:=0
  else
    FDepth:=AParent.Depth+1;
  FChilds:=TList<TTreeNode<D,T>>.Create;
end;

  function TTreeNode<D,T>.CompareTo(ATreeNode:TTreeNode<D,T>):Integer;
  begin
    Result:= Content.CompareTo(ATreeNode.Content.GetData);
  end;

  function TTreeNode<D,T>.GetChildAtIndex(AIndex:Int64):TTreeNode<D,T>;
  begin
    Result:=nil;
    if AIndex<0 then
      Exit;
    if AIndex>=ChildCount then
      Exit;
    Result:= FChilds[AIndex];
  end;

  function TTreeNode<D,T>.GetChildCount:Int64;
  begin
    Result:= FChilds.Count;
  end;

  function TTreeNode<D,T>.AddChild(AData:T):TTreeNode<D,T>;
  var
    LTreeNode:TTreeNode<D,T>;
  begin

    LTreeNode:=TTreeNode<D,T>.Create(AData,Self);
    FChilds.Add(LTreeNode);
    Result:=LTreeNode;
  end;
  {$ENDREGION}

end.
