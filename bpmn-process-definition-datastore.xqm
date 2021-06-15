(:~
 : in|FLUX base application bpmn definitions datastore
 : This datastore adapter uses the included basex-db database server.
 : The datastore is used to store BPMN 2.0 definitions.
 : The definitions are stored in a database named "definitions" containing a collection of bpmn:definitions elements.
 : @version 1.0
 : @author Sebastian Wiemer
~:)

module namespace _="http://influx.adesso.de/plugin/datastore/bpmn/process-definitions";

(: import repo modules :)
import module namespace plugin	= "influx/plugin";
import module namespace global = "influx/global";
import module namespace inspect = "http://basex.org/modules/inspect";

(: import modules from the same app :)
import module namespace resource-process-definitions = "resources/process-definitions" at "resources/process-definitions-resource.xqm";

declare namespace influx='http://influx.adesso.de/namespace';
declare namespace  bpmn    = "http://www.omg.org/spec/BPMN/20100524/MODEL";

(: declare local variables :)
declare variable $_:db-name := "definitions";
declare variable $_:ns := namespace-uri(<_:ns/>);


declare 
  %plugin:provide-default("bpmn/process-definitions")
function _:get-process-definitions(
) as element(bpmn:definitions)* {
  resource-process-definitions:get-process-definitions()
};

declare 
  %plugin:provide-default("bpmn/process-definition")
function _:get-process-definition(
    $ProcessDefinitionID as xs:string
) as element(bpmn:definitions)? {
  resource-process-definitions:get-process-definition($ProcessDefinitionID)
};

declare %plugin:provide("bpmn/process-definition/version")
function _:get-process-definition-version(
    $ProcessDefinitionID as xs:string,
    $Version as xs:string
) as element(bpmn:definitions)? {
  resource-process-definitions:get-process-definition-version($ProcessDefinitionID, $Version)
};

declare %plugin:provide("bpmn/process-definition/revision")
function _:get-process-definition-revision(
    $ProcessDefinitionID as xs:string,
    $Version as xs:string,
    $Revision as xs:string
) as element(bpmn:definitions)? {
  resource-process-definitions:get-process-definition-revision($ProcessDefinitionID, $Version, $Revision)
};

declare 
  %plugin:provide("bpmn/process-definitions/lanes")  
  %plugin:provide("lanes")
function _:get-lanes() as xs:string* {
  resource-process-definitions:get-all-process-definition-lanes()
};

declare 
  %plugin:provide-default("bpmn/process-definition/put")
  %plugin:provide-default("definition/put")
function _:put-process-definition(
    $ProcessDefinition as element(bpmn:definitions)
) as xs:string? {
  let $ProcessDefinition := _:update-provider($ProcessDefinition) return
  resource-process-definitions:put-process-definition($ProcessDefinition)
};

declare %plugin:provide-default("bpmn/process-definition/put/version")
function _:put-new-version-of-process-definition(
    $ProcessDefinition as element(bpmn:definitions)
) as xs:string? {
  let $ProcessDefinition := _:update-provider($ProcessDefinition) return
  resource-process-definitions:put-process-definition-as-new-version($ProcessDefinition)
};

declare %plugin:provide-default("bpmn/process-definition/version/create")
function _:put-new-version-of-process-definition(
    $ProcessDefinitionID as xs:string,
    $Version as xs:string,
    $Revision as xs:string,
    $DeleteRevisions as xs:boolean
) as xs:string? {
  resource-process-definitions:put-process-definition-as-new-version-from-specific-revision($ProcessDefinitionID, $Version, $Revision, $DeleteRevisions)
};

declare 
  %plugin:provide-default("bpmn/process-definition/delete")
  %plugin:provide-default("definition/delete")
function _:delete-process-definition(
    $ProcessDefinitionID as xs:string
) as empty-sequence() {
  resource-process-definitions:delete-process-definition($ProcessDefinitionID)
};

declare %plugin:provide('i18n/translations')
function _:translations(){
  doc('translations.xml')
};

declare %private
function _:update-provider(
    $ProcessDefinition as element(bpmn:definitions))
as element(bpmn:definitions){
    if (exists($ProcessDefinition/@influx:provider))
    then if ($ProcessDefinition/@influx:provider=$_:ns)
         then $ProcessDefinition
         else $ProcessDefinition update replace value of node ./@influx:provider with $_:ns
    else $ProcessDefinition update insert node attribute influx:provider {$_:ns} into .
};