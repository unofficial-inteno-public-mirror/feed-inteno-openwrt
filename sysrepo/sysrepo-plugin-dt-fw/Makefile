#
# Copyright (C) 2006-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sysrepo-plugin-dt-fw
PKG_VERSION:=1.0

PKG_LICENSE:=GPL-2.0+
PKG_MAINTAINER:=Antonio Paunovic <antonio.paunovic@sartura.hr>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/sysrepo/sysrepo-plugin-dt-fw
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=8821682
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/sysrepo-plugin-dt-fw
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+sysrepoctl +sysrepo-plugind +libblobmsg-json +libcurl +libopenssl
  TITLE:=sysrepo-plugin-dt-fw
endef

define Package/sysrepo-plugin-dt-fw/description
  sysrepo-plugin-dt-fw is a plugin daemon for sysrepo datastore. It manages firmware upgrade.
endef

define Package/sysrepo-plugin-dt-fw/install
	$(INSTALL_DIR) $(1)/usr/lib/sysrepo/plugins
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/sysrepo-plugin-dt-fw.so $(1)/usr/lib/sysrepo/plugins

	$(INSTALL_DIR) $(1)/etc/sysrepo/yang
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/yang/opencpe-firmware-mgmt@2014-02-06.yang $(1)/etc/sysrepo/yang

	$(INSTALL_DIR) $(1)/etc/cert
	$(INSTALL_BIN) ./files/sysrepo_plugin_fw.pem $(1)/etc/cert/sysrepo_plugin_fw.pem

	$(INSTALL_DIR) $(1)/etc/cert
	$(INSTALL_BIN) ./files/sysrepo_plugin_fw.pub $(1)/etc/cert/sysrepo_plugin_fw.pub

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/fw-plugin.default $(1)/etc/uci-defaults/fw-plugin.default
endef

$(eval $(call BuildPackage,sysrepo-plugin-dt-fw))
