#!/bin/bash


function dump_etcd_keys() {
  local certsdir="${OS3SRCDIR}/openshift.local.config/master"
  local creds="--cert ${certsdir}/etcd.server.crt  \
               --key ${certsdir}/etcd.server.key"

  curl ${curlopts} -q -s -k ${creds} https://127.0.0.1:4001/v2/keys/$1
}


function setup_env() {
  export OS3SRCDIR="${GOPATH}/src/github.com/openshift/origin"

  [ -d "$OS3SRCDIR" ] || export OS3SRCDIR="/vagrant"

  local osbinpath="${OS3SRCDIR}/_output/local/bin/linux/amd64"
  export PATH="${osbinpath}:${PATH}"

  alias cdos3="cd ${OS3SRCDIR}"
  alias cdos="cdos3"
  alias cdsrc="cdos3"
  alias cdpg="cd ${OS3SRCDIR}/../../ramr/src"

  local os3bin=$(which openshift) || "${osbinpath}/openshift"
  local os3startcmd="${os3bin} start --loglevel=4 &> /tmp/openshift.log"

  alias startos3="cd ${OS3SRCDIR}; sudo bash -c \"nohup ${os3startcmd} &\" "
  alias stopos3="sudo pkill openshift"
  alias restartos3="stopos3 || true; startos3"

  export KUBECONFIG="${OS3SRCDIR}/openshift.local.config/master/admin.kubeconfig"
  export OPENSHIFTCONFIG="${KUBECONFIG}"
  export CURL_CA_BUNDLE="${OS3SRCDIR}/openshift.local.config/master/ca.crt"
  [ -f "$KUBECONFIG" ] && sudo chmod +r "$KUBECONFIG"

  local voldir=/var/lib/openshift/openshift.local.volumes
  sudo mkdir -p "$voldir"
  [ -L $OS3SRCDIR/openshift.local.volumes ] || ln -s $voldir $OS3SRCDIR


}  #  End of function  setup_env.


function containerpid() {
  sudo docker inspect --format "{{ .State.Pid }}" "$1"

}  #  End of function  containerpid.


function dockexec() {
  docker exec -it "$1"

}  #  End of function  dockexec.


function enter() {
  sudo nsenter -m -u -n -i -p -t $(containerpid "$1")

}  #  End of function  enter.


function dockclean() {
  local what=${1:-"containers"}

  if [ "$what" = "all" ] || [ "$what" = "containers" ]; then
    # remove all docker containers
    docker rm $(docker ps -a -q)
  fi

  if [ "$what" = "all" ] || [ "$what" = "images" ]; then
    # remove all docker images
    docker rmi $(docker images)
  fi

}  #  End of function  dockclean.


function create_test_env() {
  openshift ex policy add-role-to-user view anypassword:test-admin

  sudo chmod +r /openshift.local.config/master/openshift-client.key
#  openshift ex registry --create --credentials="${KUBECONFIG}"

#  oc describe service docker-registry

  openshift ex new-project test --display-name="OpenShift 3 Sample"  \
     --description="Example project to demonstrate OpenShift v3"     \
     --admin=anypassword:test-admin

}  #  End of function  create_test_env.


function cleanup_router() {
  oc delete rc/router-1 dc/router se/router

}  #  End of function  cleanup_router.


function cleanup_sample_app() {
   local ns="test"
   oc delete -n $ns rc/database-1 dc/database dc/frontend se/database se/frontend

   echo " #### need to clean up pods ... "
   oc get pods -n $ns

   #  Example:
   # oc delete -n test pod build-ruby-sample-build-c72d887c-c8ed-11e4-8bc5-080027c5bfa9
   # oc delete -n test pod database-1-rxjmg

   for k in  deploymentConfigs images builds routes imageRepositories  \
	     buildConfigs ; do
     local uri="http://localhost:4001/v2/keys/${k}/${ns}?recursive=true"
     curl -s -k -X DELETE -vvv "$uri" | python -m json.tool
   done

}  #  End of function  cleanup_sample_app.


#
#  main():
#
setup_env

