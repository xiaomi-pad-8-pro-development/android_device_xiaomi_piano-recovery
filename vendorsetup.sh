# Only OrangeFox source builds consume these settings.
if [ "${PIANO_RECOVERY_FLAVOR:-}" = ofox ]; then
    export FOX_DELETE_AROMAFM=1
    export OF_MAINTAINER=ALXP
    export FOX_MAINTAINER_PATCH_VERSION=bringup-1
fi
