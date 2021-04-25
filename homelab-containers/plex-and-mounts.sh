
# smb share for media
sudo docker run \
-d \
-it \
--name samba \
-p 139:139 \
-p 445:445 \
-v /mnt/hddTV:/mount \
dperson/samba -p

# example smb.conf
#[Time Machine]
#	path = /mnt/backup/TimeMachine
#	writeable = yes
#	browseable = no
#
#	vfs objects = catia fruit streams_xattr
#
#	fruit:aapl = yes
#	fruit:time machine = yes


# mount drives
# First get device info:
lsblk
# Note the device id of the disk to be mounted, for example ‘sda1’. Then we need the UUID of the disk to be mounted, find it with the code below replacing sdXX with the correct device id from the previous step:
blkid /dev/sdXX
#The UUID looks like this:
40e554eb-6421-4813-88ea-3882a3a7a153
# Now open this file:
sudo nano /etc/fstab
# Now add this line to the end, changning the UUID for yours and /mnt/Disk should be changed to where you want to mount the disk:
UUID=50473726-ecd6-4d34-8100-f8b234f35aa5 /mnt/hddMovies auto nosuid,nodev,nofail,x-gvfs-show 0 0
UUID=9da253f8-0618-4d8f-9d51-853d154936ab /mnt/hddTV auto nosuid,nodev,nofail,x-gvfs-show 0 0
# Ctrl+X, then ‘Y’ to save and exit.

# PLEX
# PLEX - export claim token
export PLEXTOKEN='claim-EFCJs7nY79d6X9HLfgaZ'

# export host IP
export HOSTIP=`ip addr show ens160 | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}'`

# export timezone of host
export HOSTTZ=`timedatectl show | gawk -F'=' ' $1 ~ /Timezone/ {print $2}'`

# export media directories
export TVDIR='/mnt/hddTV/LGSmartTV/TV'
export MOVIESDIR='/mnt/hddMovies/LGSmartTV/Movies'
export MUSICDIR='/mnt/hddMovies/Music'

# export docker config root
export DOCKERCONFIGDIR='/opt/docker'

# PLEX - run container
docker run \
-d \
--name plex \
-p 32400:32400/tcp \
-p 3005:3005/tcp \
-p 8324:8324/tcp \
-p 32469:32469/tcp \
-p 1900:1900/udp \
-p 32410:32410/udp \
-p 32412:32412/udp \
-p 32413:32413/udp \
-p 32414:32414/udp \
--network=host \
-e TZ="$HOSTTZ" \
-e PLEX_UID=1000 -e PLEX_GID=1000 \
-e PLEX_CLAIM="$PLEXTOKEN" \
-e ADVERTISE_IP="http://$HOSTIP:32400/" \
-v $DOCKERCONFIGDIR/plex/config:/config \
-v $TVDIR:/data/tvshows \
-v $MOVIESDIR:/data/movies \
-v $MUSICDIR:/data/music \
--restart unless-stopped \
plexinc/pms-docker:latest

