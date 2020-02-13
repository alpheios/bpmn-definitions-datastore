module namespace _ = "tests/integration/mock-provider";

import module namespace plugin = "influx/plugin";

declare %plugin:provide-mock('username')
function _:mock-username() {
    'test-user'
};