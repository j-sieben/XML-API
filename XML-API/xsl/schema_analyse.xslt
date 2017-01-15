<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" exclude-result-prefixes="xsl xs  fn xsd"/>
	<xsl:template match="/">
		<schema>
			<xsl:apply-templates select="xsd:schema/xsd:element" mode="einsprungpunkte"/>
		</schema>
	</xsl:template>
	<!-- EINSPRUNKGPUNKTE -->
	<xsl:template match="xsd:element" mode="einsprungpunkte">
		<einsprungpunkt namespace="{/xsd:schema/@targetNamespace}" name="{@name}" comment="{xsd:annotation/xsd:documentation/text()}">
			<xsl:apply-templates select="xsd:complexType/xsd:sequence/*" mode="inhalt"/>
		</einsprungpunkt>
	</xsl:template>
	<!-- ELEMENTE -->
	<xsl:template match="xsd:element" mode="inhalt">
		<!-- mehrfach erlaubtes Element, choice-Element mit innerer Struktur -->
		<xsl:if test="(@maxOccurs > '0' or @maxOccurs = 'unbounded')  or (parent::xsd:choice and descendant::xsd:element)">
			<element name="{@name}" parent="{ancestor-or-self::xsd:element[2]/@name}" position="{position()}">
				<xsl:attribute name="path"><xsl:call-template name="genPath"/></xsl:attribute>
				<xsl:attribute name="choice"><xsl:choose><xsl:when test="parent::xsd:choice">Y</xsl:when><xsl:otherwise>N</xsl:otherwise></xsl:choose></xsl:attribute>
				<xsl:attribute name="multi"><xsl:choose><xsl:when test="@maxOccurs > '0' or @maxOccurs = 'unbounded'">Y</xsl:when><xsl:otherwise>N</xsl:otherwise></xsl:choose></xsl:attribute>
				<xsl:element name="{@name}">
					<xsl:apply-templates select="xsd:complexType/xsd:sequence/xsd:element[not(@maxOccurs > '0' or @maxOccurs = 'unbounded')]|xsd:complexType/xsd:sequence/xsd:choice/xsd:element" mode="repeatable"/>
				</xsl:element>
			</element>
		</xsl:if>
		<xsl:apply-templates select="xsd:complexType/xsd:sequence/*|xsd:element" mode="inhalt"/>
	</xsl:template>
	<xsl:template match="xsd:element[not(xsd:complexType)]" mode="inhalt">
		<element name="{@name}" parent="{ancestor-or-self::xsd:element[2]/@name}" position="{position()}">
			<xsl:attribute name="choice"><xsl:choose><xsl:when test="parent::xsd:choice">Y</xsl:when><xsl:otherwise>N</xsl:otherwise></xsl:choose></xsl:attribute>
			<xsl:attribute name="optional"><xsl:choose><xsl:when test="@minOccurs = 0">Y</xsl:when><xsl:otherwise>N</xsl:otherwise></xsl:choose></xsl:attribute>
			<xsl:if test="@type">
				<xsl:attribute name="dataType">char(1)</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="path"><xsl:call-template name="genPath"/></xsl:attribute>
			<xsl:apply-templates select="xsd:simpleType|xsd:element/@type" mode="inhalt"/>
		</element>
	</xsl:template>
	<!-- PFADE GENERIEREN -->
	<xsl:template name="genPath">
		<xsl:param name="prevPath"/>
		<xsl:variable name="currPath">
			<xsl:choose>
				<xsl:when test="name()='xsd:element'">
					<xsl:value-of select="concat('/',@name,$prevPath)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$prevPath"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:for-each select="parent::*">
			<xsl:call-template name="genPath">
				<xsl:with-param name="prevPath" select="$currPath"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:if test="not(parent::*)">
			<xsl:value-of select="$currPath"/>
		</xsl:if>
	</xsl:template>
	<!-- WIEDERHOLBARE ELEMENTE, CHOICES MIT KINDERN -->
	<xsl:template match="xsd:element" mode="repeatable">
		<xsl:element name="{@name}">
			<xsl:apply-templates select="xsd:complexType/xsd:sequence/xsd:element[not(@maxOccurs > '0' or @maxOccurs = 'unbounded')]" mode="repeatable"/>
		</xsl:element>
	</xsl:template>
	<!-- DATENTYPEN -->
	<xsl:template match="xsd:simpleType" mode="inhalt">
		<xsl:apply-templates select="*" mode="inhalt"/>
	</xsl:template>
	<xsl:template match="xsd:restriction[@base='xsd:string']" mode="inhalt">
		<xsl:choose>
			<xsl:when test="xsd:maxLength|xsd:length">
				<xsl:attribute name="dataType">varchar2(<xsl:value-of select="xsd:maxLength/@value|xsd:length/@value"/>)</xsl:attribute>
			</xsl:when>
			<xsl:when test="xsd:pattern">
				<xsl:attribute name="dataType">varchar2(<xsl:value-of select="substring-after(substring-before(xsd:pattern/@value, '}'), '{')"/>)</xsl:attribute>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xsd:restriction[@base='xsd:unsignedInt']" mode="inhalt">
		<xsl:attribute name="dataType">number(<xsl:value-of select="xsd:totalDigits/@value"/>,0)</xsl:attribute>
	</xsl:template>
	<xsl:template match="xsd:restriction[@base='xsd:decimal']" mode="inhalt">
		<xsl:attribute name="dataType">number(<xsl:value-of select="xsd:totalDigits/@value"/>,<xsl:value-of select="xsd:fractionDigits/@value"/>)</xsl:attribute>
	</xsl:template>
	<xsl:template match="xsd:restriction[@base='xsd:integer']" mode="inhalt">
		<xsl:attribute name="dataType">number(<xsl:value-of select="xsd:totalDigits/@value"/>,0)</xsl:attribute>
	</xsl:template>
</xsl:stylesheet>
