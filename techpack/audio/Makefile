include $(srctree)/techpack/audio/config/lahainaauto.conf

USERINCLUDE     += \
                -I$(srctree)/techpack/audio/include/uapi/audio

LINUXINCLUDE    += \
                -I$(srctree)/techpack/audio/include/uapi \
                -I$(srctree)/techpack/audio/include/uapi/audio \
                -I$(srctree)/techpack/audio/include/asoc \
                -I$(srctree)/techpack/audio/include

ifeq ($(CONFIG_MIUS_PROXIMITY), y)
LINUXINCLUDE    += \
                -I$(srctree)/techpack/audio/include/mius
endif

LINUXINCLUDE    += \
                -include $(srctree)/techpack/audio/config/lahainaautoconf.h

#obj-y += soc/
#obj-y += dsp/
#obj-y += ipc/
#obj-y += asoc/
