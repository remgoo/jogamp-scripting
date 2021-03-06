#!/bin/sh

if [ $# -ne 1 ]
then
  echo "usage: version" 1>&2
  exit 1
fi

VERSION="$1"
shift

cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project
  xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <!--                                                                 -->
  <!-- Auto generated by joal.pom.sh, do not edit directly! -->
  <!--                                                                 -->

  <modelVersion>4.0.0</modelVersion>
  <groupId>org.jogamp.joal</groupId>
  <artifactId>joal</artifactId>
  <version>${VERSION}</version>
  <packaging>jar</packaging>
  <name>JOAL</name>
  <description>Java™ Binding for the OpenAL® API</description>
  <url>http://jogamp.org/joal/www/</url>

EOF

cat joal.pom.in || exit 1
cat <<EOF
</project>
EOF
