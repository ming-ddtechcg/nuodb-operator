#!/bin/bash
operator-courier verify $TRAVIS_BUILD_DIR/deploy/olm-catalog/nuodb-operator/0.0.5/

operator-courier verify --ui_validate_io $TRAVIS_BUILD_DIR/deploy/olm-catalog/nuodb-operator/0.0.5/

echo "Operator verification completed."
