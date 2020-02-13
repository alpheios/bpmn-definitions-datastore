module namespace _ = "resources/process-definitions";

(: import repo modules :)
import module namespace global	= "influx/global";
import module namespace plugin	= "influx/plugin";
import module namespace db	    = "influx/db";

(: import modules from the same app :)
import module namespace app = "http://influx.adesso.de/plugin/datastore/bpmn/process-definitions" at "../bpmn-process-definition-datastore.xqm";

declare namespace meta = "http://influx.adesso.de/metadata";
declare namespace version = "http://influx.adesso.de/version";
declare namespace bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL";
declare namespace influx = "http://influx.adesso.de/namespace";
declare variable $_:ns := namespace-uri(<_:ns/>);


(: read  :)
declare function _:get-process-definitions(
) as element(bpmn:definitions)* {
  let $query := "db:open($db, 'definitions/latest')/*:definitions"
  let $variables := map {
    "db": $app:db-name
  }
  let $definition := db:eval($query, $variables)
  return
    if ($definition)
    then
        let $definition := $definition update for $x in ./bpmn:definitions return delete node $x/@influx:provider
        let $definition := $definition update for $x in ./bpmn:definitions return insert node attribute influx:provider {$app:ns} into $x
        return $definition
    else $definition
};

declare function _:get-process-definition(
    $ProcessDefinitionID as xs:string
) as element(bpmn:definitions)? {
  let $query := "db:open($db, 'definitions/latest/'||$processDefinitionID||'.xml')/*:definitions"
  let $variables := map {
    "db": $app:db-name,
    "processDefinitionID": $ProcessDefinitionID
  }
  let $definition := db:eval($query, $variables)
  return
    $definition update
    if (not(exists(./@influx:provider)))
      then insert node attribute {"influx:provider"} {$app:ns} into .
      else replace value of node ./@influx:provider with $app:ns
};

declare function _:get-process-definition-version(
  $ProcessDefinitionID as xs:string,
  $Version as xs:string
) as element()? {
  let $query := "db:open($db, 'definitions/'||$processDefinitionID||'/version/'||$version||'/'||$processDefinitionID||'.xml')/*:definitions"
  let $variables := map {
    "db": $app:db-name,
    "processDefinitionID": $ProcessDefinitionID,
    "version": $Version
  }
  let $definition := db:eval($query, $variables)
  return
    if ($definition)
    then
        let $definition := $definition update delete node ./@influx:provider
        let $definition := $definition update insert node attribute influx:provider {$app:ns} into .
        return $definition
    else $definition
};

declare function _:get-process-definition-revision(
  $ProcessDefinitionID as xs:string,
  $Version as xs:string,
  $Revision as xs:string
) as element()? {
  let $query := "db:open($db, 'definitions/'||$processDefinitionID||'/version/'||$version||'/revision/'||$revision)/*:definitions"
  let $variables := map {
    "db": $app:db-name,
    "processDefinitionID": $ProcessDefinitionID,
    "version": $Version,
    "revision": $Revision
  }
  let $definition := db:eval($query, $variables)
  return
    if ($definition)
    then
        let $definition := $definition update delete node ./@influx:provider
        let $definition := $definition update insert node attribute influx:provider {$app:ns} into .
        return $definition
    else $definition
};

declare function _:get-all-process-definition-lanes(
) as xs:string* {
  let $query := "db:open($db, 'definitions/latest')/*:definitions//*:lane/@name/string()"
  let $variables := map {
    "db": $app:db-name
  }
  return
    db:eval($query, $variables)
};


(: update  :)
(: TODO xQDoc Comments :)
declare function _:put-process-definition(
    $ProcessDefinition as element()
) as xs:string? {
  let $ProcessDefinition :=
    if(exists($ProcessDefinition/@id)) then $ProcessDefinition
    else $ProcessDefinition update insert node attribute id { random:uuid() } into .
  (: Check if there is a provider for creating a revision (check for versioning!) :)
  let $processDefinitionMeta := plugin:lookup("meta/versioning/latest")!.($ProcessDefinition/@id)
  let $newProcessDefinitionMeta := _:create-version-or-revision-of-process-definition($ProcessDefinition/@id/string(), $processDefinitionMeta/@id/string(), false())
  let $processDefinitionVersion := $newProcessDefinitionMeta/version:version/string()
  let $processDefinitionRevision := $newProcessDefinitionMeta/version:revision/string()

  let $processDefinitionVersioningDbPath := _:generate-process-definition-db-path($ProcessDefinition/@id/string(), $processDefinitionVersion, $processDefinitionRevision)
  let $putProcessDefinitionWithVersioningQuerySegment := if ($processDefinitionVersioningDbPath)
                                                        then "db:replace($db, '"||$processDefinitionVersioningDbPath||"', $processDefinition)"
                                                        else "()"

  let $query := "(db:replace($db, 'definitions/latest/'||$processDefinition/@id/string()||'.xml', $processDefinition),"||$putProcessDefinitionWithVersioningQuerySegment||")"
  let $variables := map {
    "db": $app:db-name,
    "processDefinition": $ProcessDefinition
  }
  return
    db:eval($query, $variables)
};

declare function _:put-process-definition-as-new-version(
    $ProcessDefinition as element()
) as xs:string? {
  (: Check if there are any meta data corresponding to the defininition with the given ID :)
  let $processDefinitionMeta := plugin:lookup("meta/versioning/latest")!.($ProcessDefinition/@id)
  return if ($processDefinitionMeta) then (
    (: TODO: Remove old Revisions from DB :)
    let $newProcessDefinitionMeta := _:create-version-or-revision-of-process-definition($ProcessDefinition/@id/string(), $processDefinitionMeta/@id/string(), true())
    let $processDefinitionVersion := $newProcessDefinitionMeta/version:version/string()
    let $processDefinitionRevision := $newProcessDefinitionMeta/version:revision/string()

    let $processDefinitionVersioningDbPath := _:generate-process-definition-db-path($ProcessDefinition/@id/string(), $processDefinitionVersion, $processDefinitionRevision)
    let $putProcessDefinitionWithVersioningQuerySegment := if ($processDefinitionVersioningDbPath)
                                                          then "db:replace($db, '"||$processDefinitionVersioningDbPath||"', $processDefinition)"
                                                          else "()"

    let $query := "(db:replace($db, 'definitions/latest/'||$processDefinition/@id/string()||'.xml', $processDefinition),"||$putProcessDefinitionWithVersioningQuerySegment||")"
    let $variables := map {
      "db": $app:db-name,
      "processDefinition": $ProcessDefinition
    }
    return
      db:eval($query, $variables)
  ) else (
    _:put-process-definition($ProcessDefinition)
  )
};

declare function _:put-process-definition-as-new-version-from-specific-revision(
    $ProcessDefinitionID as xs:string,
    $Version as xs:string,
    $Revision as xs:string,
    $DeleteRevisions as xs:boolean
) as xs:string? {
    let $processDefinitionRevisionMetaID := $ProcessDefinitionID || '-' || $Version || '-' || $Revision
    let $processDefinition := _:get-process-definition-revision($ProcessDefinitionID, $Version, $Revision)

    (: TODO: Remove old Revisions from DB :)
    let $newProcessDefinitionVersionMetaID := plugin:lookup("meta/version/create")!.($processDefinitionRevisionMetaID, $DeleteRevisions)
    let $processDefinitionVersion := plugin:lookup("meta")!.($newProcessDefinitionVersionMetaID)/version:version/string()

    let $processDefinitionVersioningDbPath := _:generate-process-definition-db-path($ProcessDefinitionID, $processDefinitionVersion, ())
    let $putProcessDefinitionWithVersioningQuerySegment := if ($processDefinitionVersioningDbPath)
                                                          then "db:replace($db, '"||$processDefinitionVersioningDbPath||"', $processDefinition)"
                                                          else "()"

    let $deleteOldRevisionsOfProcessDefinitionQuerySegment := if ($DeleteRevisions)
                                                          then "db:delete($db, 'definitions/'||$processDefinition/@id/string()||'/version/'||$version||'/revision')"
                                                          else "()"

    let $query := "(db:replace($db, 'definitions/latest/'||$processDefinition/@id/string()||'.xml', $processDefinition)," ||
                  $putProcessDefinitionWithVersioningQuerySegment || "," || $deleteOldRevisionsOfProcessDefinitionQuerySegment || ")"
    let $variables := map {
      "db": $app:db-name,
      "processDefinition": $processDefinition,
      "version": $Version
    }
    return
      db:eval($query, $variables)
};
  
(: delete :)
declare function _:delete-process-definition(
    $ProcessDefinitionID as xs:string
) as empty-sequence() {
  (: Check if there are any meta data corresponding to the defininition with the given ID and delete them :)
  let $processDefinitionMeta := plugin:lookup("meta/versioning/latest")!.($ProcessDefinitionID)
  let $deleteProcessDefinitionMeta := if ($processDefinitionMeta)
                                      then plugin:lookup("meta/versioning/purge")!.($ProcessDefinitionID)
                                      else ()
  let $query := "(db:delete($db, 'definitions/latest/'||$processDefinitionID||'.xml'),
                  db:delete($db, 'definitions/'||$processDefinitionID))"
  let $variables := map {
    "db": $app:db-name,
    "processDefinitionID": $ProcessDefinitionID
  }
  return
    db:eval($query, $variables)
};

(: version manager handling functions :)

(: TODO: xQDoc Comments :)
declare function _:generate-process-definition-db-path(
    $ProcessDefinitionID as xs:string,
    $Version as xs:string?,
    $Revision as xs:string?
) as xs:string? {
  if($Version)
  then (
    let $revisionPathSegment := if($Revision and not($Revision="1"))
                                then (
                                  "/revision/" || $Revision
                                ) else ""
    return "definitions/" || $ProcessDefinitionID || "/version/" || $Version || $revisionPathSegment || "/" || $ProcessDefinitionID || ".xml"
  ) else ()
};

(: TODO: xQDoc Comments :)
declare function _:create-version-or-revision-of-process-definition(
    $ProcessDefinitionID as xs:string,
    $ProcessDefinitionMetaID as xs:string?,
    $CreateVersion as xs:boolean
) as element(meta:meta)? {
  (: check for versioning :)
  let $newID := if ($CreateVersion) then (
                  if ($ProcessDefinitionMetaID) (: when there is any meta element corresponding to that definition :)
                  then
                    plugin:lookup("meta/version/create")!.($ProcessDefinitionMetaID, true())
                  else (: when there is no meta element corresponding to that definition :)
                    plugin:lookup("meta/version/create")!.($ProcessDefinitionID, true())
                ) else (
                  if ($ProcessDefinitionMetaID)
                  then
                    plugin:lookup("meta/revision/create")!.($ProcessDefinitionMetaID)
                  else
                    plugin:lookup("meta/revision/create")!.($ProcessDefinitionID)
                )
  let $newMeta := if ($newID)
                  then plugin:lookup("meta/versioning/latest")!.($ProcessDefinitionID)
                  else ()
  return
    $newMeta
};