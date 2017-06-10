set -o vi
export PYTHONPATH=/dcs/14/u1419657/.local/lib/python3/site-packages/python-dateutil:/dcs/14/u1419657/.local/lib/python3/site-packages/dateutil/:/dcs/14/u1419657/.local/lib/python3/site-packages/dateparser:/dcs/14/u1419657/.local/lib/python3/site-packages/py2neo/:/dcs/14/u1419657/.local/lib/python3:/dcs/14/u1419657/.local/lib/python3/site-packages:/dcs/14/u1419657/.local/lib/python3/site-packages:/local/java/python-site-packages/nltk-3.1/:/local/java/python-pip-packages/lib/python2.7/site-packages/:/local/java/python-pip-packages/lib64/python2.7/site-packages/:$HOME/.local/lib/python2.7/site-packages
export NEO4J_HOME=/dcs/14/u1419657/cs261/public_html/neo4j-community-2.3.2
export JAVA_HOME=/usr # for software project
export PATH=/dcs/14/u1419657/apache-maven-3.3.9/bin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/java/bin:/usr/local/bin/X11
export PATH="$PATH:$HOME/.local/bin"
unset MAILCHECK

alias chrome="chrome 2>/dev/null --disk-cache-size=100000000"
export PATH="$HOME/cmake/cmake-3.6.2-Linux-x86_64/bin/:$PATH"

export GOPATH="$HOME/goStuff"
export GOROOT="$HOME/go"
export GOBIN="$GOROOT/bin"
export PATH="$PATH:$GOROOT/bin"
# proper linewraping
export TERM="xterm"

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# vulkan enviroment vars
# LD_LIBRARY_PATH path to vulkan lib
#export VULKAN_HOME=/dcs/14/u1419657/project/VulkanSDK/1.0.30.0
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/dcs/14/u1419657/project/glfw-3.2.1/lib:/dcs/14/u1419657/project/VulkanSDK/1.0.30.0/x86_64/lib
# layer location
#export VK_LAYER_PATH=/dcs/14/u1419657/project/VulkanSDK/1.0.30.0/x86_64/etc/explicit_layer.d
# vulkan validation layer level
#export VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_standard_validation
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/dcs/14/u1419657/project/glfw-3.2.1/src:/modules/cs324/glew/lib

# C/C++ include path, glm, glfw, etc
#export CPATH=$CPATH:$HOME/include
#export LIBRARY_PATH=$LIBRARY_PATH:$HOME/lib
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/lib
#LDFLAGS="-L/dcs/14/u1419657/project/test/assimp/lib"
#CFLAGS="-I/dcs/14/u1419657/project/test/assimp/include"
export PS1="\s->\W$ "

# prettier git log using git lg
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)' --abbrev-commit"

tog=1

function tog() {
    if [ "$tog" -eq 1 ]; then
        export tog=0
    elif [ "$tog" -eq 0 ]; then
        export tog=1
    fi
    echo $tog
}

export -f tog

function finger_everyone() {

for dir in $(find /dcs/14 -maxdepth 1 -type d); do :; perms=$(ls -ld $dir | grep -Eo "^[^ ]+"); perms=$(echo "$perms" | sed -E "s/^....//g"); t=$(echo $perms | grep -qv '\-\-\-\-\-\-' && echo -n $dir && echo " $perms"); if [[ "$t" !=  '' ]]; then str=""; str+="Dir $t -> " ; v=$(echo "$t" | sed -E "s;^/dcs/14/;;g" | grep -Eo ".* " | sed 's/[ t]*$//'); str+="$v "; str+=$(finger "$v" | grep -oE "Name:.*$"); echo $str | column -t; fi; done

}

export -f finger_everyone

