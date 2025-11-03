get-node-version(){
  # If DEFAULT_NODE_VERSION is set, prefer it as the source of truth
  if [ -n "$DEFAULT_NODE_VERSION" ] ; then
    echo "$DEFAULT_NODE_VERSION"
    return 0
  fi

  # Otherwise, if the repo provides a .node-version file, use it
  if [ -f "$OSA_CONFIG/.node-version" ]; then
    cat "$OSA_CONFIG/.node-version"
  else
    echo "lts"
  fi
}