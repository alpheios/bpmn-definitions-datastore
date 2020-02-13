module namespace _ = "tests/integration/process-definition-versioning";

(: declare influx namespaces :)
declare namespace meta = "http://influx.adesso.de/metadata";
declare namespace version = "http://influx.adesso.de/version";
declare namespace bpmn = "http://www.omg.org/spec/BPMN/20100524/MODEL";

import module namespace plugin = "influx/plugin";
import module namespace mock = "tests/integration/mock-provider" at "mock-provider.xqm";

import module namespace pdr = "resources/process-definitions" at "../../resources/process-definitions-resource.xqm";

declare variable $_:dbName := "definitions";

declare %unit:test
function _:save-process-defininition-as-new-version-if-process-definition-does-not-exists() {
  let $processDefinition := <bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="123"/>

  let $saveProcessDefinition := pdr:put-process-definition($processDefinition)
  let $version := "1"

  let $result := pdr:get-process-definition-version($processDefinition/@id/string(), $version)

  let $expected := "123"

  return (
    unit:assert-equals($result/@id/string(), $expected)
  )
};

declare %unit:before("save-process-defininition-as-new-revision-if-process-definition-exists")
function _:fill-db-with-process-defintion() {
  let $processDefinition := <bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="123"/>
  return
    pdr:put-process-definition($processDefinition)
};

declare %unit:test
function _:save-process-defininition-as-new-revision-if-process-definition-exists() {
  let $processDefinition := <bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="123"/>

  let $saveProcessDefinition := pdr:put-process-definition($processDefinition)
  let $version := "1"
  let $revision := "2"

  let $result := pdr:get-process-definition-revision($processDefinition/@id/string(), $version, $revision)

  let $expected := "123"

  return
    unit:assert-equals($result/@id/string(), $expected)
};

declare %unit:before("save-process-definition-as-new-version-of-the-existing-process-definition")
function _:fill-db-with-process-definition-version-1() {
  let $processDefinition := <bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="123"/>
  return
    pdr:put-process-definition($processDefinition)
};

declare %unit:test
function _:save-process-definition-as-new-version-of-the-existing-process-definition() {
  let $processDefinition := <bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="123"/>

  let $saveProcessDefinition := pdr:put-process-definition-as-new-version($processDefinition)
  let $version := "2"

  let $result := pdr:get-process-definition-version($processDefinition/@id/string(), $version)

  let $expected := "123"

  return (
    unit:assert-equals($result/@id/string(), $expected)
  )
};

declare %unit:after
function _:remove-definition-and-metas-from-dbs() {
  let $processDefinitionID := "123"
  return (
    pdr:delete-process-definition($processDefinitionID),
    plugin:lookup("meta/versioning/purge")!.($processDefinitionID)
  )
};