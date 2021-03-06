------------------------------------------------------------------------
Maven deployment scripts
------------------------------------------------------------------------

The purpose of these scripts is to produce a set of PGP-signed jars and
POM files for deployment to Maven Central.

  http://search.maven.org

Because the jogamp projects do not use Maven to manage their own builds
(and it would be too much work for very little gain to convert the build
system over to Maven), these scripts take an archive of already-released
jar files and produce renamed jar files and POM files as output, ready
for deployment to the repository.

These instructions assume that you know how to set up a PGP agent [0].

In order to get packages onto Maven Central, it's necessary to have an
account on one of the large Java "forges". The most-used one seems to be
Sonatype. See the repository usage guide [1] for details on getting an
account.

------------------------------------------------------------------------
Instructions (deploying a release to Central)
------------------------------------------------------------------------

  1. Obtain the jogamp-all-platforms.7z release for the version
     of jogamp you wish to deploy to Central. As an example, we'll
     use 2.0-rc11. Unpack the 7z file to the 'input' subdirectory,
     creating it if it doesn't exist:

    $ mkdir input
    $ cd input
    $ wget http://jogamp.org/deployment/v2.0-rc11/archive/jogamp-all-platforms.7z
    $ 7z x jogamp-all-platforms.7z

  2. Switch back to the old directory:

    $ cd ..

  3. The Central repository requires PGP signatures on all files
     deployed to the repository. Because we'll be signing a lot
     of files, we need this to occur in the most automated manner
     possible. Therefore, we need to tell Maven which PGP key to
     use and also to tell it to use any running PGP agent we have.
     To do this, we have to add a profile to $HOME/.m2/settings.xml
     that sets various properties that tell the PGP plugin what
     to do. My settings.xml looks something like:

     <?xml version="1.0" encoding="UTF-8"?>
     <settings
       xmlns="http://maven.apache.org/SETTINGS/1.0.0" 
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
       xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
       <profiles>
         <profile>
           <id>jogamp-deployment</id>
           <properties>
             <gpg.useagent>true</gpg.useagent>
             <gpg.keyname>jogamp.com (Release signing key)</gpg.keyname>
           </properties>
         </profile>
       </profiles>
       <activeProfiles>
         <activeProfile>jogamp-deployment</activeProfile>
       </activeProfiles>
     </settings>

    That is, I've defined a new profile called "jogamp-deployment"
    that enables the use of a PGP agent, and uses the string
    "jogamp.com (Release signing key)" to tell PGP which key to use.
    You can obviously use the fingerprint of the key here too
    (or anything else that uniquely identifies it).

    See: http://www.sonatype.com/books/mvnref-book/reference/profiles.html

  4. Now, run make.sh with the desired version number to generate POM
     files and copy jar files to the correct places:

      $ ./make.sh 2.0-rc11

  5. The scripts will have created an 'output' directory, containing
     all the prepared releases. It's now necessary to deploy the releases,
     one at a time [2]. Assuming that our Sonatype username is 'jogamp'
     and our password is '********', we now need to edit settings.xml
     to tell Maven to use them both:

     <?xml version="1.0" encoding="UTF-8"?>
     <settings
       xmlns="http://maven.apache.org/SETTINGS/1.0.0" 
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
       xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
       <profiles>
         <profile>
           <id>jogamp-deployment</id>
           <properties>
             <gpg.useagent>true</gpg.useagent>
             <gpg.keyname>jogamp.com (Release signing key)</gpg.keyname>
           </properties>
         </profile>
       </profiles>
       <activeProfiles>
         <activeProfile>jogamp-deployment</activeProfile>
       </activeProfiles>
      <servers>
        <server>
          <id>sonatype-nexus-staging</id>
          <username>jogamp</username>
          <password>********</password>
        </server>
      </servers>
     </settings>

     That is, we define a new server called 'sonatype-nexus-staging' (this
     is the name that the scripts use to refer to the remote repository),
     and state that it wants username 'jogamp' and password '********'.

  6. Now we can deploy an individual project to the staging repository:

      $ ./make-deploy-one.sh gluegen-rt-main 2.0-rc11

     Or deploy all of the projects defined in make-projects.txt:

      $ ./make-deploy.sh 2.0-rc11

     The scripts will upload all necessary jars, poms, signatures, etc.

  7. Now, we need to tell the Sonatype repository that we wish to actually
     promote the uploaded ("staged") files to a release. This step (unfortunately)
     doesn't seem to be possible from the command line.

     Log in to https://oss.sonatype.org using the 'jogamp:********' username
     and password.

     Click 'Staging repositories' in the left navigation bar.

     In the main pane, there should now be a table of repositories. Because
     we've just uploaded a set of files, there should be one entry (staging
     repositories are automatically created when files are uploaded).

     Click the checkbox to the left of the repository name. This will open
     a 'repository browser' below the main view, showing a tree of files.
     Inspect the tree of files to be sure that all of the necessary files are
     present.

     If all files are there, and assuming that the checkbox is still selected
     from the previous step, click the 'Close' button above the repository
     browser - this will 'close' the staging repository (meaning no new files
     can be added). Then click 'Release' when you absolutely positively want
     to commit. The release will be made official and the files synced to
     the Central repository within two hours.

     If there are still more projects to release, return to step 6.

------------------------------------------------------------------------
Projects
------------------------------------------------------------------------

The way that Maven works demanded a certain structure to the projects
produced. The requirements were:

  1. The end-user of the jogamp projects released to the repository
     must not have to do anything beyond adding one or two dependencies
     to their own projects. Everything must work using only the basic
     dependency resolution mechanism that Maven supports and must not
     require anything complex in the way of build scripts.

  2. The way that jogamp projects locate their own jar files must
     work as it always had.

The first requirement was reasonably easy to satisfy (and the details
of which will be covered shortly). The second requirement was complicated
by the fact that Maven unconditionally appends version numbers to jar
files (and requires the numbers to be present in order for the dependency
resolution to work). After trying various approaches, a small change was
made to the jogamp code in order to allow it to cope with version numbers,
and the Maven projects were carefully structured to produce jar files
with usable names. In other words, we had to essentially write Maven
POM files that, when "deployed", produced jar files with the correct
names, using a variety of tricks. The other issue was that jogamp implicitly
assumed that all of the jar files would be in the same directory, whereas
Maven essentially assumes one directory per jar file.

We ended up with the following structure: For each part of jogamp that
had associated native binaries (contained within jar files), a project
was created. Then, using the "classifiers" [3], each of the native jar
files were deployed along with the main jar file for each project. Using
'gluegen-rt' as an example:

  The main jar file as part of jogamp is "gluegen-rt.jar". When
  "deployed" by Maven, this becomes "gluegen-rt-${VERSION}.jar".

  Each native jar file associated with gluegen-rt is named
  "gluegen-rt-natives-${OS}-${ARCH}.jar". We use "classifiers" to
  get Maven to "deploy" jar files with the correct names:

    PLATFORMS="linux-amd64 linux-i586 ..."
    for PLATFORM in ${PLATFORMS}
    do
      CLASS="natives-${PLATFORM}"
      mvn gpg:sign-and-deploy-file \
        -Dfile="gluegen-rt-${VERSION}-natives-${PLATFORM}.jar \
        -Dclassifier="natives-${PLATFORM}"
    done

  Assuming version 2.0-rc11, this results in:

    gluegen-rt-2.0-rc11.jar
    gluegen-rt-2.0-rc11-natives-linux-amd64.jar
    gluegen-rt-2.0-rc11-natives-linux-i586.jar
    ...

This results in a project with a main jar and a set of native jar
files, each with the correct name and version. As the native jar
files are implicitly part of the same "project", they're deployed
in the same directory as the main jar file, and the jogamp code can
locate them without issue.

The problem with this approach is that the end-user would have
to add an explicit dependency on "gluegen-rt" and each and every
one of the associated native jars in their project's POM file! The
simplest solution for this problem was to create a second project
that contained explicit dependencies on all of the classified jar
files of the first. The end-user then simply adds a dependency on
this second project instead of the first, and everything is resolved
automatically by Maven. This second project also contains an empty
"dummy" jar file in order to allow Maven to deploy it to repositories.

With that in mind, each part of Maven therefore has an associated
"-main" project, meant to be used by end-users. This "-main" project,
when added to the dependencies of any project, pulls in all of the
real jogamp jars, native or otherwise.

------------------------------------------------------------------------
Notes
------------------------------------------------------------------------

We're currently uploading empty jar files for the "sources" and
"javadoc" jars required by Central. The rules state that these
files are required unconditionally, but may be empty in the case
that there aren't sources or javadoc. It'd be nice to provide real
sources and javadoc one day.

------------------------------------------------------------------------
Footnotes
------------------------------------------------------------------------

[0] http://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html

[1] https://docs.sonatype.org/display/Repository/Sonatype+OSS+Maven+Repository+Usage+Guide

[2] Sonatype seems to have the restriction that it's only possible to
    deploy one 'artifactId' at a time - that translates to deploying one
    jogamp project at a time.

[3] https://maven.apache.org/plugins/maven-deploy-plugin/examples/deploying-with-classifiers.html

[4] http://www.jcraft.com/jsch/
