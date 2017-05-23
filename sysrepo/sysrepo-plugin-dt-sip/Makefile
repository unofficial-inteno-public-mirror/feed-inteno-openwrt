#
# Copyright (C) 2006-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sysrepo-plugin-dt-sip
PKG_VERSION:=1.0

PKG_LICENSE:=GPL-2.0+
PKG_MAINTAINER:=Antonio Paunovic <antonio.paunovic@sartura.hr>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/sysrepo/sysrepo-plugin-dt-sip
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=92769fc

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/sysrepo-plugin-dt-sip
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libuci +libubus +sysrepoctl +sysrepo-plugind +libblobmsg-json
  TITLE:=sysrepo-plugin-dt-sip
endef

define Package/sysrepo-plugin-dt-sip/description
  sysrepo-plugin-dt-sip is a plugin daemon for sysrepo datastore. It manages SIP asterisk configuration.
endef

define Package/sysrepo-plugin-dt-sip/install
	$(INSTALL_DIR) $(1)/usr/lib/sysrepo/plugins
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/sysrepo-plugin-dt-sip.so $(1)/usr/lib/sysrepo/plugins

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/config/asterisk $(1)/etc/config/

	$(INSTALL_DIR) $(1)/etc/sysrepo/yang
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/yang/sip@2015-10-06.yang $(1)/etc/sysrepo/yang

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/sip-plugin.default $(1)/etc/uci-defaults/sip-plugin.default
endef

$(eval $(call BuildPackage,sysrepo-plugin-dt-sip))
