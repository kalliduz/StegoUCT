program UTestGoEngine;

{$mode objfpc}{$H+}

uses
  simpletestrunner, testregistry,
  Test.BoardControls;

begin
  with TTestRunner.Create(nil) do
  begin
    Run;
    Free;
  end;
end.
