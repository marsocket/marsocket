# Copyright (C) 2019 marsocket <marsocket@gmail.com>
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=marsocket
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=marsocket <marsocket@gmail.com>

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$(PKG_VERSION)
PKG_HASH:=9732f8b8f02ffeea261bcf15fbf104f826012f74dbee99d016b75f0894a39649

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=c-ares pcre

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/marsocket
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Marsocket for Shadowsocks.
  URL:=https://github.com/marsocket/marsocket
  PKGARCH:=all
  DEPENDS:=+dns-forwarder \
			+ipset +ip-full +iptables \
			+iptables-mod-tproxy +iptables-mod-extra \
			+coreutils +coreutils-base64 +haveged +curl \
			+libev +libmbedtls +libpthread +libsodium +libcares +libpcre
endef

define Package/marsocket/prerm/Default
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for $(1)"
     /etc/init.d/$(1) disable
     /etc/init.d/$(1) stop
    echo "Removing firewall rule for $(1)"
	  uci -q batch <<-EOF >/dev/null
		delete firewall.$(1)
		commit firewall
EOF
fi
exit 0
endef
Package/marsocket/prerm = $(call Package/marsocket/prerm/Default,marsocket)

define Package/marsocket/postinst/Default
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.$(1)
		set firewall.$(1)=include
		set firewall.$(1).type=script
		set firewall.$(1).path=/var/etc/$(1)/firewall.include
		set firewall.$(1).reload=0
		commit firewall
EOF
fi
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-$(1) ) && rm -f /etc/uci-defaults/luci-$(1)
	chmod 755 /etc/init.d/$(1) >/dev/null 2>&1
	/etc/init.d/$(1) enable >/dev/null 2>&1
fi
exit 0
endef
Package/marsocket/postinst = $(call Package/marsocket/postinst/Default,marsocket)

define Package/marsocket/conffiles
  /etc/config/marsocket
endef

define Package/marsocket/install/Default
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/$(2).*.lmo $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/root/usr/bin/* $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ss-redir $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ss-tunnel $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ss-local $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/$(2).lua $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/$(2)
	$(INSTALL_DATA) ./files/luci/model/cbi/$(2)/*.lua $(1)/usr/lib/lua/luci/model/cbi/$(2)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/$(2)
	$(INSTALL_DATA) ./files/luci/view/$(2)/*.htm $(1)/usr/lib/lua/luci/view/$(2)
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/root/etc/config/* $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/root/etc/init.d/* $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/$(2)
	$(INSTALL_DATA) ./files/root/etc/$(2)/* $(1)/etc/$(2)
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/* $(1)/etc/uci-defaults
endef
Package/marsocket/install = $(call Package/marsocket/install/Default,$(1),marsocket)

define Build/Prepare
	$(call Build/Prepare/Default)
	$(FIND) $(PKG_BUILD_DIR) \
					   -name '*.o' \
					-o -name '*.lo' \
					-o -name '.deps' \
					-o -name '.libs' \
			| $(XARGS) rm -rvf
	$(foreach po,$(wildcard ${CURDIR}/files/luci/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

CONFIGURE_ARGS += \
        --disable-documentation \
        --disable-silent-rules \
        --disable-assert \
        --disable-ssp \

TARGET_CFLAGS += -flto
TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

$(eval $(call BuildPackage,marsocket))

