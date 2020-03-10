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

    // first print warnings for props no longer used
    retired.each |r|
    {
      if (map.containsKey(r))
        Env.cur.err.printLine("# [studs.props] '$r' prop no longer used")
    }

    this.system = findSystem
    this.jre    = findJre
  }

  ** Get the value for given property name, or 'null' if name not found.
  @Operator Str? get(Str name) { map[name] }

  ** The configured system for this project.
  const System system

  ** The configured JRE for this project.
  const Jre jre

  ** Find a system image based on props.
  private System findSystem()
  {
    name := map["system.name"]
    if (name == null) abort("Missing 'system.name' prop")

    arch := map["system.arch"]
    uri  := map["system.uri"]?.toUri

    // check if we matched a def version; allow uri to be
    // overrided for testing unrelased images
    def := System.find(name, false)
    if (def != null)
    {
      if (uri == null) return def
      return System {
        it.name    = def.name
        it.arch    = def.arch
        it.version = def.version
        it.uri     = uri
      }
    }

    if (arch == null) abort("Missing 'system.arch' prop")
    if (uri  == null) abort("Missing 'system.uri' prop")

    base := uri.name[0..<-".tar.gz".size]
    ver  := base["studs-system-$name-".size..-1]

    // create a custom system from props
    return System {
      it.name    = name
      it.arch    = arch
      it.version = Version(ver)
      it.uri     = uri
    }
  }

  ** Find a JRE image based on props.
  private Jre findJre()
  {
    // TODO
    return Jre.find(system.arch)
  }

  ** Print the given error message then exit with error code.
  private static Void abort(Str msg)
  {
    Env.cur.err.printLine("ERR [studs.props]: ${msg}")
    Env.cur.exit(1)
  }

  private static const Str:Str retired := [:].setList([
    "target.bb",
    "target.rpi0",
    "target.rpi3",
  ])

  private const File file
  private const Str:Str map
}