#!/bin/bash

echo "Checking all test cases for all safety requirements."

# Arrays of files
data_files=( ./rdf/* )
shacl_files=( ./shacl/* )
query_files=( ./sparql/* )
# Lengths of arrays
n1=${#data_files[@]}
n2=${#query_files[@]}
n3=${#shacl_files[@]}

# Validate first
failed_validations=0
for (( i = 0 ; i < n1; i++ )); do
  echo "Checking test case ${data_files[i]} for model validity."
  # Loop over shacl validations
  for (( k = 0; k < n3; k++ )); do
    shacl validate --shapes ${shacl_files[k]} --data ${data_files[i]} > /tmp/shacl_result
    cat /tmp/shacl_result | grep "  sh:conforms  true" > /dev/null
    if [ $? -eq 0 ]; then
      echo "Test case ${data_files[i]} validated successfully with SHACL shapes file ${shacl_files[k]}."
    else
      ((failed_validations++))
      echo "Test case ${data_files[i]} failed valdiation with SHACL shapes file ${shacl_files[k]}."
      echo "Validation report:"
      cat /tmp/shacl_result
    fi
  done
done

if [ $failed_validations -gt 0 ]; then
  echo "Some test cases failed validation. Please ensure all models are valid."
  exit 1
else
  echo "Validation completed successfully."
  echo "" # newline
fi


# Loop over data files
failed_test_cases=0
for (( i = 0 ; i < n1; i++ )); do
  echo "Checking test case ${data_files[i]} for compliance with safety requirements:"
  # Loop over queries
  # Count failed requirements
  failed_reqs=0
  for (( j = 0 ; j < n2; j++ )); do
    cat ${query_files[j]} | grep "# Requirement"
    sparql --data ${data_files[i]} --query ${query_files[j]} > /tmp/sparql_result
    cat /tmp/sparql_result | grep "poc" > /dev/null
    if [ $? -eq 0 ]; then
      ((failed_reqs++))
      cat ${query_files[j]} | grep "# Violation"
      cat /tmp/sparql_result
    else
      echo "# Requirement met."
    fi
    echo "" # newline
  done
  # Report results of queries
  if [ $failed_reqs -eq 0 ]; then
    echo "All requirements met for test case ${data_files[i]}"
  else
    ((failed_test_cases++))
    echo "${failed_reqs} requirement(s) were not met for test case ${data_files[i]}"
  fi
  echo "" # newline
done
# Report results overall
if [ $failed_test_cases -eq 0 ]; then
  echo "All test cases passed all requirements"
  exit 0
else
  echo "${failed_test_cases} test case(s) failed to pass all requirements."
  exit 1
fi
