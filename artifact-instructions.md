# Instructions for Running Violat

This file is to be used in the artifact evaluation of the Violat tool.

## What’s Included

* These instructions: `/home/cav/README.md`.
* The Violat tool paper submission: `/home/cav/violat-tool-paper.pdf`
* A script to run examples from the tool paper: `/home/cav/run-examples.sh`
* Violat’s source code: `/home/cav/Code/violat`.

Violat is built mainly with Node.js and Java 8, and otherwise depends on Maven and Gradle. See Violat’s `README.md` for more information.

## Extreme Quick Start

Replicate the functionality demonstrated in the tool paper.

````bash
bash run-examples.sh
````

## Basic Usage

Violat is invoked via the `violat-validator` command. When no arguments are provided, Violat prints a standard usage message:
````bash
$ violat-validator

  Find test harnesses that expose linearizability violations.

  Usage
    $ violat-validator <spec-file.json>

  Options
    --tester TESTER
    --schema STRING
    --java-home PATH
    --jar STRING
    --method-filter REGEXP
    --maximality
    --max-programs N
    --min-threads N
    --max-threads N
    --min-invocations N
    --max-invocations N
    --min-values N
    --max-values N
    --time-per-test N
    --iters-per-test N
    --forks-per-test N

  Examples
    $ violat-validator ConcurrentHashMap.json
    $ violat-validator --schema "{ clear(); put(0,1) } || { containsKey(1); remove(0) }" ConcurrentHashMap.json
````

The only required argument is a class specification file, written in JSON format. This specification provides basic information about method signatures, which Violat uses this specification to generate programs that invoke the specified class’s methods. The `resources/specs` directory contains standard examples for Java’s concurrent collections. For instance, consider an excerpt from `resources/spec/java/util/concurrent/ConcurrentHashMap.json`:

````json
{
  "class": "java.util.concurrent.ConcurrentHashMap",
  "harnessParameters": {
        "invocations": 3
  },
  "methods": [
    {
      "name": "containsKey",
      "parameters": [
        {"type": "java.lang.Object"}
      ],
      "void": false,
      "readonly": true,
      "trusted": true,
      "visibility": "complete"
    },
    {
      "name": "get",
      "parameters": [
        {"type": "java.lang.Object"}
      ],
      "void": false,
      "readonly": true,
      "trusted": true,
      "visibility": "complete"
    },
    {
      "name": "put",
      "parameters": [
        {"type": "java.lang.Object"},
        {"type": "java.lang.Object"}
      ],
      "void": false,
      "readonly": false,
      "trusted": true,
      "visibility": "complete"
    },
    {
      "name": "remove",
      "parameters": [
        {"type": "java.lang.Object"}
      ],
      "void": false,
      "readonly": false,
      "trusted": true,
      "visibility": "complete"
    },
    {
      "name": "clear",
      "parameters": [],
      "void": true,
      "readonly": false,
      "trusted": false,
      "harnessParameters": {
        "invocations": 5
      }
    },
    {
      "name": "containsValue",
      "parameters": [
        {"type": "java.lang.Object"}
      ],
      "void": false,
      "readonly": true,
      "trusted": false,
      "harnessParameters": {
        "invocations": 5
      },
      "visibility": "monotonic"
    },
    {
      "name": "contains",
      "parameters": [
        {"type": "java.lang.Object"}
      ],
      "void": false,
      "readonly": true,
      "trusted": false,
      "harnessParameters": {
        "invocations": 4
      },
      "visibility": "monotonic"
    },
    ...
  ]
}
````

Besides providing parameter types, this specification marks the `containsKey`, `get`, `put`, and `remove` operations of `java.util.ConcurrentHashMap` as `trusted`, and with `complete` visibility. The `clear`, `containsValue`, and `contains` operations are marked as untrusted, and the latter two are given `monotonic` visibility.

### Trusted vs. untrusted methods

Violat uses the trusted property to generate tests which contain relatively few untrusted method invocations. This helps to focus the blame of any discovered inconsistent results towards those methods which are not trusted. As a general rule, the *core* operations of a data structure, like `get`, `put`, `remove`, and `containsKey` in the above example are marked as trusted — many other operations are built on top of these primitives, or otherwise more likely to provide weaker guarantees.

### Visibility: complete vs. monotonic vs. unspecified

Violat checks consistency of a given test program against the provided visibility annotations. Generally speaking, the *core* operations of a concurrent collection are expected to be atomic, i.e.,~appearing to execute at one single instant, rather than interfered with by other concurrent operations. The methodology of [visibility relaxation] captures this atomic consistency with the `complete` annotation, meaning that these operations must see every operation linearized before it. Other operations often exhibit weaker consistencies, and are annotated with correspondingly weaker visibility guarantees, like `monotonic` and `weak`. Some operations, like `clear`, cannot even be ascribed consistencies according to visibility relaxation, and are thus left unspecified. Violat reports consistency violations against these specifications, thus methods with unspecified visibilities will not be checked.

[visibility relaxation]: http://michael-emmi.github.io/papers/conf-popl-EmmiE19.pdf

The subtlety of weak consistency can be completely ignored by annotating every method with the `complete` visibility. This will instruct Violat to report any atomicity violation, which can be readily observed among Java’s concurrent collections.

### Violat’s output

Violat outputs any discovered violations to the console directly — see the examples below. Additionally, Violat generates plenty of intermediate files in the `violat-output` subdirectory of the current working directory. Additionally, the various components of Violat can generate plenty of debug output by adding the appropriate tags to the DEBUG variable. For example the following generates debug output for all components.

````
DEBUG=* violat-validator MySpec.json
````

Alternative, specific components can be selected:

````
DEBUG=testing,enum:random violat-validator MySpec.json
````

These tags can be found in the corresponding source components. For example, the `src/enumeration/random.ts` module declares the following:

````typescript
const debug = Debug('enum:random');
````

## A Few Simple Examples

Let’s first copy the concurrent hash map spec, but change all visibilities to `complete`. I’ll assume we’re working out of `/home/cav/Code/violat`, but Violat can be invoked from any directory.

````bash
cd /home/cav/Code/violat

echo "Copy the ConcurrentHashMap spec"
cp resources/specs/java/util/concurrent/ConcurrentHashMap.json MySpec.json

echo
echo "Change monotonic to complete visibility"
sed -i'' 's/monotonic/complete/g' MySpec.json

echo
echo "Change weak to complete visibility"
sed -i'' 's/weak/complete/g' MySpec.json

echo
echo "Add visibilities to clear, size, mappingCount"
sed -i'' 's/\("name": "clear"\)/\1, "visibility": "complete"/g' MySpec.json
sed -i'' 's/\("name": "size"\)/\1, "visibility": "complete"/g' MySpec.json
sed -i'' 's/\("name": "mappingCount"\)/\1, "visibility": "complete"/g' MySpec.json
````

As an initial sanity check, let’s run Violat on a specific program schema, using Java Pathfinder to cover all paths:

````
$ violat-validator MySpec.json --schema "{ remove(0); elements(); isEmpty() } || { put(1,1) }" --tester "Java Pathfinder"
violat version 0.5.20
---
violation discovered
---
{ remove(0); elements(); isEmpty() } || { put(1,1) }
---
outcome                 OK  frequency
----------------------  --  ---------
null, [], true, null    √   3        
null, [], false, null   √   3        
null, [1], true, null   X   3        
null, [1], false, null  √   3        

---
Found 1 violations.
````

Notice the consistency violation discovered.

Now let’s unleash Violat to discover any atomicity violations in the first 100 programs it generates and tests, via stress testing. Note that the frequencies generated below are during 1 second of stress testing per program on a native installation; these frequencies may differ significantly when run on a VM, due to performance overhead, as well as resource availability.

````
$ violat-validator MySpec.json
violat version 0.5.20
---
violation discovered
---
{ remove(0); elements(); isEmpty() } || { put(1,1) }
---
outcome                 OK  frequency
----------------------  --  ---------
null, [1], false, null  √   345,557  
null, [1], true, null   X   2        
null, [], false, null   √   384      
null, [], true, null    √   4,697    

---
violation discovered
---
{ elements(); isEmpty(); contains(1); keys() } || { put(1,0); elements() }
---
outcome                            OK  frequency
---------------------------------  --  ---------
[0], false, false, [1], null, [0]  √   490,619  
[0], true, false, [1], null, [0]   X   2        
[], false, false, [1], null, [0]   √   14,476   
[], true, false, [1], null, [0]    √   3,310    
[], true, false, [], null, [0]     √   37,073   

---
Found 2 violations.
````

### Caution when Running on a VM

To get a feel for how far off the VM instance is from my native installation, let’s compare your output to mine with the following command. On my native installation I see:

````
DEBUG=testing violat-validator MySpec.json --schema "{ remove(0); elements(); isEmpty() } || { put(1,1) }"
violat version 0.5.20
---
  testing computing expected outcomes for 1 programs +0ms
  testing running test framework +378ms
  testing initializing test framework +1ms
  testing got result:
  testing { remove(0); elements(); isEmpty() } || { put(1,1) }
outcome                 OK  frequency
----------------------  --  ---------
null, [1], false, null  √   1,630,436
null, [1], true, null   X   8        
null, [], false, null   √   6,813    
null, [], true, null    √   10,633   

 +8s
violation discovered
---
{ remove(0); elements(); isEmpty() } || { put(1,1) }
---
outcome                 OK  frequency
----------------------  --  ---------
null, [1], false, null  √   1,630,436
null, [1], true, null   X   8        
null, [], false, null   √   6,813    
null, [], true, null    √   10,633   

---
Found 1 violations.
````

While running on a VM I see the following:

````
DEBUG=testing violat-validator MySpec.json --schema "{ remove(0); elements(); isEmpty() } || { put(1,1) }"
violat version 0.5.20
---
  testing computing expected outcomes for 1 programs +0ms
  testing running test framework +213ms
  testing initializing test framework +1ms
  testing got result:
  testing { remove(0); elements(); isEmpty() } || { put(1,1) }
outcome                 OK  frequency
----------------------  --  ---------
null, [1], false, null  √   81,973   
null, [], false, null   √   5        
null, [], true, null    √   59,532   

 +9s
Found 0 violations.
````

That’s a pretty huge difference in execution frequencies, so I might recommend sticking to the Java Pathfinder back-end instead (see above) if you’ll be running Violat inside a VM.

### Back to the Story

Interesting, let’s see whether Java Pathfinder finds the same violations. Note that this will take much longer: Violat spends only 1 second per test on while stress testing, while Java Pathfinder will spend as long as it takes to cover every path through the given test program. Note that the results of these commands should be identical whether or not you’re running on a VM — but they make take much longer!

````
$ violat-validator MySpec.json --tester "Java Pathfinder"
violat version 0.5.20
---
violation discovered
---
{ remove(1); toString() } || { put(1,1); remove(1); elements(); isEmpty() }
---
outcome                         OK  frequency
------------------------------  --  ---------
null, {}, null, 1, [], true     √   3        
null, {1=1}, null, 1, [], true  √   3        
1, {}, null, null, [], true     √   3        
1, {}, null, null, [], false    X   3        

---
violation discovered
---
{ put(0,1); elements() } || { keys(); isEmpty(); containsValue(0) }
---
outcome                       OK  frequency
----------------------------  --  ---------
null, [1], [0], false, false  √   3        
null, [1], [0], true, false   X   3        
null, [1], [], false, false   √   3        
null, [1], [], true, false    √   3        

---
violation discovered
---
{ put(0,0); remove(1) } || { put(1,1); keys(); toString() }
---
outcome                             OK  frequency
----------------------------------  --  ---------
null, null, null, [0,1], {0=0,1=1}  √   3        
null, 1, null, [0], {0=0}           √   3        
null, 1, null, [0,1], {0=0}         √   3        
null, 1, null, [0,1], {0=0,1=1}     √   3        
null, 1, null, [], {0=0}            X   3        
null, 1, null, [1], {0=0}           √   3        
null, 1, null, [1], {0=0,1=1}       √   3        
null, 1, null, [1], {}              X   3        
null, 1, null, [1], {1=1}           √   3        

---
violation discovered
---
{ elements(); isEmpty(); contains(1); keys() } || { put(1,0); elements() }
---
outcome                            OK  frequency
---------------------------------  --  ---------
[], true, false, [], null, [0]     √   3        
[], true, false, [1], null, [0]    √   3        
[], false, false, [1], null, [0]   √   3        
[0], true, false, [1], null, [0]   X   3        
[0], false, false, [1], null, [0]  √   3        

---
violation discovered
---
{ values() } || { put(0,1); toString(); put(1,0) }
---
outcome                   OK  frequency
------------------------  --  ---------
[], null, {0=1}, null     √   3        
[0], null, {0=1}, null    X   3        
[1], null, {0=1}, null    √   3        
[1,0], null, {0=1}, null  √   3        

---
violation discovered
---
{ put(0,0); put(1,0); put(1,0) } || { keys(); put(0,1); contains(0) }
---
outcome                        OK  frequency
-----------------------------  --  ---------
null, null, 0, [0,1], 0, true  √   3        
null, null, 0, [0], 0, true    √   3        
null, null, 0, [0], 0, false   √   3        
null, null, 0, [1], 0, true    X   3        
null, null, 0, [], 0, true     √   3        
null, null, 0, [], 0, false    √   3        
1, null, 0, [], null, true     √   3        
1, null, 0, [], null, false    √   3        

---
violation discovered
---
{ remove(0); elements(); isEmpty() } || { put(1,1) }
---
outcome                 OK  frequency
----------------------  --  ---------
null, [], true, null    √   3        
null, [], false, null   √   3        
null, [1], true, null   X   3        
null, [1], false, null  √   3        

---
Found 7 violations.
````

Interesting, it looks like Java Pathfinder managed to uncover those violations (reported in a different order) as well as some violations that weren’t seen during stress testing. Let’s feed one of those program schemas directly into Violat, and allow more time for stress testing.

````
$ violat-validator MySpec.json --schema "{ remove(1); toString() } || { put(1,1); remove(1); elements(); isEmpty() }" --time-per-test 10
violat version 0.5.20
---
violation discovered
---
{ remove(1); toString() } || { put(1,1); remove(1); elements(); isEmpty() }
---
outcome                         OK  frequency
------------------------------  --  ----------
1, {}, null, null, [], false    X   1         
1, {}, null, null, [], true     √   1,793     
null, {1=1}, null, 1, [], true  √   8,080     
null, {}, null, 1, [], true     √   27,719,816

---
Found 1 violations.
````

Ah hah — given enough time, stress testing managed to tease that one out too.

## Further Exploration

Violat is very much a research prototype, and could do a better job of input validation and exception handling. However, it is also open source, and it’s not too hard to find out where the issues are using the DEBUG output.
