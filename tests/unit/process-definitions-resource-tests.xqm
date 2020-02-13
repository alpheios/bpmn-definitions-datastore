module namespace _ = "tests/unit/process-definitions-resource";

import module namespace pdr = "resources/process-definitions" at "../../resources/process-definitions-resource.xqm";

declare %unit:test
function _:generate-process-definition-db-path-without-version-and-revision() {

    let $processDefinitionID := "b3620c7b-9300-4736-854f-472f6063000a"
    let $version := ()
    let $revision := ()

    let $result := pdr:generate-process-definition-db-path($processDefinitionID, $version, $revision)

    let $expected := ()

    return
      unit:assert-equals($result, $expected)
};

declare %unit:test
function _:generate-process-definition-db-path-with-version-and-without-revision() {

    let $processDefinitionID := "b3620c7b-9300-4736-854f-472f6063000a"
    let $version := "1"
    let $revision := ()

    let $result := pdr:generate-process-definition-db-path($processDefinitionID, $version, $revision)

    let $expected := "definitions/" || $processDefinitionID || "/version/" || $version || "/" || $processDefinitionID || ".xml"

    return
      unit:assert-equals($result, $expected)
};

declare %unit:test
function _:generate-process-definition-db-path-without-version-and-with-revision() {

    let $processDefinitionID := "b3620c7b-9300-4736-854f-472f6063000a"
    let $version := ()
    let $revision := "1"

    let $result := pdr:generate-process-definition-db-path($processDefinitionID, $version, $revision)

    let $expected := ()

    return
      unit:assert-equals($result, $expected)
};

declare %unit:test
function _:generate-process-definition-db-path-with-version-and-revision() {

    let $processDefinitionID := "b3620c7b-9300-4736-854f-472f6063000a"
    let $version := "1"
    let $revision := "2"

    let $result := pdr:generate-process-definition-db-path($processDefinitionID, $version, $revision)

    let $expected := "definitions/" || $processDefinitionID || "/version/" || $version || "/revision/" || $revision || "/" || $processDefinitionID || ".xml"

    return
      unit:assert-equals($result, $expected)
};


declare %unit:test
function _:generate-process-definition-db-path-with-version-and-revision-equals-1() {

    let $processDefinitionID := "b3620c7b-9300-4736-854f-472f6063000a"
    let $version := "1"
    let $revision := "1"

    let $result := pdr:generate-process-definition-db-path($processDefinitionID, $version, $revision)

    let $expected := "definitions/" || $processDefinitionID || "/version/" || $version || "/" || $processDefinitionID || ".xml"

    return
      unit:assert-equals($result, $expected)
};