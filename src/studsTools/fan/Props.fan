//
// Copyright (c) 2017, Andy Frank
// Licensed under the Apache License version 2.0
//
// History:
//   18 Jan 2017  Andy Frank  Creation
//

using util

**
** Props models a projects 'studs.props' file.
**
const class Props
{
  ** Ctor.
  new make()
  {
    f := Env.cur.workDir + `studs.props`
    if (!f.exists)
    {
      Env.cur.err.printLine("project not found: $Env.cur.workDir.osPath")
      Env.cur.exit(1)
    }

    this.file = f
    this.map  = f.readProps

    // print warnings for props no longer used
    retired.each |r|
    {
      if (map.containsKey(r))
        Env.cur.err.printLine("# [studs.props] '$r' prop no longer used")
    }

    // find systems
    systems := System[,]
    map.each |val,key|
    {
      if (key.startsWith("target.") && val == "true")
      {
        name := key["target.".size..-1]
        uri  := map["target.${name}.uri"]?.toUri
        if (uri == null)
        {
          // default system
          systems.add(System.makeDef(name))
        }
        else
        {
          // custom system
          base := uri.name[0..<-".tar.gz".size]
          ver  := base["studs-system-$name-".size..-1]
          systems.add(System {
            it.name = name
            it.version = Version(ver)
            it.uri     = uri
          })
        }
      }
    }
    this.systems  = systems
  }

  ** Get the value for given property name, or 'null' if name not found.
  @Operator Str? get(Str name) { map[name] }

  ** List of configured systems for this project.
  const System[] systems

  ** Find a configured System with given name. If system not found
  ** throw Err if 'checked' is true, otherwise return 'null'.
  System? system(Str name, Bool checked := true)
  {
    sys := systems.find |s| { s.name == name }
    if (sys == null && checked) throw Err("System not found '$name'")
    return sys
  }

  private static const Str:Str retired := [:].setList([,])

  private const File file
  private const Str:Str map
}