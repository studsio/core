//
// Copyright (c) 2016, Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 2016  Andy Frank  Creation
//

using studs

class ServiceTest : Test
{
  Void test()
  {
    // TODO

    ServiceMgr {
      it.services = [
        TestServiceA(),
        TestServiceB(),
        TestServiceC(),
      ]
    }.start

    concurrent::Actor.sleep(10sec)
  }
}

internal const class TestServiceA : StudsService
{
  new make() : super("TestA", 1sec) {}
  override Void onStart() { echo("TestA: started") }
  override Void onStop() { echo("TestA: stopped") }
  override Void onPoll() { echo("TestA: poll"); throw Err("Oops") }
}

internal const class TestServiceB : StudsService
{
  new make() : super("TestB", 2sec) {}
  override Void onStart() { echo("TestB: started") }
  override Void onStop() { echo("TestB: stopped") }
  override Void onPoll() { echo("TestB: poll") }
}

internal const class TestServiceC : StudsService
{
  new make() : super("TestC", 3sec) {}
  override Void onStart() { echo("TestC: started") }
  override Void onStop() { echo("TestC: stopped") }
  override Void onPoll() { echo("TestC: poll") }
}