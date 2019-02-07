
cd /home/cav/Code/violat

echo
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

echo
echo "Run Violat on the examples from Figure 2."
violat-validator MySpec.json --schema "{ put(0,0); put(1,1); put(1,1)} || { put(0,1); clear() }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(0,0); remove(1) } || { put(1,0); contains(0) }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ get(1); containsValue(1) } || { put(1,1); put(0,1); put(1,0) }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(0,1); put(1,0) } || { elements() }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(0,1); put(1,0) } || { entrySet() }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(1,1) } || { put(1,2); isEmpty() }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(0,1); put(1,1) } || { keySet() }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ keys()} || { put(0,1); put(1,1) }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(1,0); put(1,1); mappingCount() } || { remove(1) }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(1,0); put(1,1); size()} || { remove(1) }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(0,1); put(1,1) } || { toString() }" --tester "Java Pathfinder"
violat-validator MySpec.json --schema "{ put(0,1); put(1,0) } || { values() }" --tester "Java Pathfinder"

echo
echo "Show the predicated outcomes for this schema, as in Section 4."
DEBUG=prediction violat-validator MySpec.json --schema "{ get(1); containsValue(1) } || { put(1,1); put(0,1); put(1,0) }" --tester "Java Pathfinder"

echo
echo "Show the code generated for Java Pathfinder, like in Figure 3."
DEBUG=jpf:harness violat-validator MySpec.json --schema "{ get(1); containsValue(1) } || { put(1,1); put(0,1); put(1,0) }" --tester "Java Pathfinder"
