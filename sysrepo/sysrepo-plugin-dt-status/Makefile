#
# Copyright (C) 2006-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sysrepo-plugin-dt-status
PKG_VERSION:=1.0

PKG_LICENSE:=GPL-2.0+
PKG_MAINTAINER:=Antonio Paunovic <antonio.paunovic@sartura.hr>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/sysrepo/sysrepo-plugin-dt-status
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=02d1a2b
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/sysrepo-plugin-dt-status
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+sysrepoctl +sysrepo-plugind +libblobmsg-json +libuci +libjson-c +libubus
  TITLE:=sysrepo-plugin-dt-status
endef

define Package/sysrepo-plugin-dt-status/description
  sysrepo-plugin-dt-status is a plugin daemon for sysrepo datastore. It manages status information.
endef

define Package/sysrepo-plugin-dt-status/install
	$(INSTALL_DIR) $(1)/usr/lib/sysrepo/plugins
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/sysrepo-plugin-dt-status.so $(1)/usr/lib/sysrepo/plugins

	$(INSTALL_DIR) $(1)/etc/sysrepo/yang
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/yang/status@2015-12-1.yang $(1)/etc/sysrepo/yang

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/status-plugin.default $(1)/etc/uci-defaults/status-plugin.default
endef

$(eval $(call BuildPackage,sysrepo-plugin-dt-status))
