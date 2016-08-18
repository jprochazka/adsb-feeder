<?php

    /////////////////////////////////////////////////////////////////////////////////////
    //                            ADS-B RECEIVER PORTAL                                //
    // =============================================================================== //
    // Copyright and Licensing Information:                                            //
    //                                                                                 //
    // The MIT License (MIT)                                                           //
    //                                                                                 //
    // Copyright (c) 2015-2016 Joseph A. Prochazka                                     //
    //                                                                                 //
    // Permission is hereby granted, free of charge, to any person obtaining a copy    //
    // of this software and associated documentation files (the "Software"), to deal   //
    // in the Software without restriction, including without limitation the rights    //
    // to use, copy, modify, merge, publish, distribute, sublicense, and/or sell       //
    // copies of the Software, and to permit persons to whom the Software is           //
    // furnished to do so, subject to the following conditions:                        //
    //                                                                                 //
    // The above copyright notice and this permission notice shall be included in all  //
    // copies or substantial portions of the Software.                                 //
    //                                                                                 //
    // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR      //
    // IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,        //
    // FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE     //
    // AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER          //
    // LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,   //
    // OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE   //
    // SOFTWARE.                                                                       //
    /////////////////////////////////////////////////////////////////////////////////////

    require_once('../classes/common.class.php');
    require_once('../classes/settings.class.php');

    $common = new common();
    $settings = new settings();

    // The most current stable release.
    $thisVersion = "2.0.3";

    // Begin the upgrade process if this release is newer than what is installed.
    if ($common->getSetting("version") == $thisVersion) {
        header ("Location: /");
    }

    $error = FALSE;
    #errorMessage = "No error message returned.";

    ///////////////////////
    // UPGRADE TO V2.0.1
    ///////////////////////

    if ($common->getSetting("version") == "2.0.0") {
        try {
            // Change tables containing datetime data to datetime.
            if ($settings::db_driver != "xml") {

                // ALter MySQL tables.
                if ($settings::db_driver != "mysql") {
                    $dbh = $common->pdoOpen();

                    $sql = "ALTER TABLE ".$settings::db_prefix."aircraft MODIFY firstSeen DATETIME NOT NULL";
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    $sth = NULL;

                    $sql = "ALTER TABLE adsb_aircraft MODIFY lastSeen DATETIME NOT NULL";
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    $sth = NULL;

                    $sql = "ALTER TABLE adsb_blogPosts MODIFY date DATETIME NOT NULL";
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    $sth = NULL;

                    $sql = "ALTER TABLE adsb_flights MODIFY firstSeen DATETIME NOT NULL";
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    $sth = NULL;

                    $sql = "ALTER TABLE adsb_flights MODIFY firstSeen DATETIME NOT NULL";
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    $sth = NULL;

                    $sql = "ALTER TABLE adsb_positions MODIFY time DATETIME NOT NULL";
                    $sth = $dbh->prepare($sql);
                    $sth->execute();
                    $sth = NULL;

                    $dbh = NULL;
                }

                // Convert times to GMT.

                // You may wish to uncomment this block of code in order to convert existing times
                // stored in the database to UTC/GMT time. Before doing so it is recommended that
                // you set the setting max_execution_time setting to a large amount of time in your
                // php.ini file. Depending on the amount of flight data logged this may take quite
                // some time for this upgrade script to complete so be patient and let it run it's
                // course. Afterwards set the max_execution_time back to it previous setting.

                /*
                $dbh = $common->pdoOpen();
                $sql = "SELECT id, firstSeen, lastSeen FROM ".$settings::db_prefix."aircraft";
                $sth = $dbh->prepare($sql);
                $sth->execute();
                $aircraft = $sth->fetchAll();
                $sth = NULL;
                $dbh = NULL;

                foreach ($aircraft as $airframe) {
                    $dbh = $common->pdoOpen();
                    $sql = "UPDATE ".$settings::db_prefix."aircraft SET firstSeen = :firstSeen, lastSeen = :lastSeen WHERE id = :id";
                    $sth = $dbh->prepare($sql);
                    $sth->bindParam(':firstSeen',  gmdate("Y-m-d H:i:s", $airframe["firstSeen"]), PDO::PARAM_STR);
                    $sth->bindParam(':lastSeen', gmdate("Y-m-d H:i:s", $airframe["lastSeen"]), PDO::PARAM_STR);
                    $sth->bindParam(':id', $airframe["id"], PDO::PARAM_INT);
                    $sth->execute();
                    $sth = NULL;
                    $dbh = NULL;
                }

                $dbh = $common->pdoOpen();
                $sql = "SELECT id, date FROM ".$settings::db_prefix."blogPosts";
                $sth = $dbh->prepare($sql);
                $sth->execute();
                $blogPosts = $sth->fetchAll();
                $sth = NULL;
                $dbh = NULL;

                foreach ($blogPosts as $post) {
                    $dbh = $common->pdoOpen();
                    $sql = "UPDATE ".$settings::db_prefix."blogPosts SET date = :date WHERE id = :id";
                    $sth = $dbh->prepare($sql);
                    $sth->bindParam(':date', gmdate("Y-m-d H:i:s", $post["date"]), PDO::PARAM_STR);
                    $sth->bindParam(':id', $post["id"], PDO::PARAM_INT);
                    $sth->execute();
                    $sth = NULL;
                    $dbh = NULL;
                }

                $dbh = $common->pdoOpen();
                $sql = "SELECT id, firstSeen, lastSeen FROM ".$settings::db_prefix."flights";
                $sth = $dbh->prepare($sql);
                $sth->execute();
                $flights = $sth->fetchAll();
                $sth = NULL;
                $dbh = NULL;

                foreach ($flights as $flight) {
                    $dbh = $common->pdoOpen();
                    $sql = "UPDATE ".$settings::db_prefix."flights SET firstSeen = :firstSeen, lastSeen = lastSeen WHERE id = :id";
                    $sth = $dbh->prepare($sql);
                    $sth->bindParam(':firstSeen', gmdate("Y-m-d H:i:s", $flight["firstSeen"]), PDO::PARAM_STR);
                    $sth->bindParam(':lastSeen', gmdate("Y-m-d H:i:s", $flight["lastSeen"]), PDO::PARAM_STR);
                    $sth->bindParam(':id', $flight["id"], PDO::PARAM_INT);
                    $sth->execute();
                    $sth = NULL;
                    $dbh = NULL;
                }

                $dbh = $common->pdoOpen();
                $sql = "SELECT id, time FROM ".$settings::db_prefix."positions";
                $sth = $dbh->prepare($sql);
                $sth->execute();
                $positionss = $sth->fetchAll();
                $sth = NULL;
                $dbh = NULL;

                foreach ($positions as $position) {
                    $dbh = $common->pdoOpen();
                    $sql = "UPDATE ".$settings::db_prefix."positions SET time = :time WHERE id = :id";
                    $sth = $dbh->prepare($sql);
                    $sth->bindParam(':time', gmdate("Y-m-d H:i:s", $position["time"]), PDO::PARAM_STR);
                    $sth->bindParam(':id', $position["id"], PDO::PARAM_INT);
                    $sth->execute();
                    $sth = NULL;
                    $dbh = NULL;
                }
                */
            }

            // Add timezone setting.
            $common->addSetting("timeZone", date_default_timezone_get());

            // update version and patch settings.
            $common->updateSetting("version", "2.0.1");
            $common->updateSetting("patch", "");
        } catch(Exception $e) {
            $error = TRUE;
            $errorMessage = $e->getMessage();
        }
    }

    ///////////////////////
    // UPGRADE RO V2.0.2
    ///////////////////////

    if ($common->getSetting("version") == "2.0.1") {
        try {

            // Set proper permissions on the SQLite file.
            if ($settings::db_driver == "sqlite") {
                chmod($_SERVER['DOCUMENT_ROOT'].DIRECTORY_SEPARATOR."data".DIRECTORY_SEPARATOR."portal.sqlite", 0666);
            }

            $common->updateSetting("version", "2.0.2");
            $common->updateSetting("patch", "");
        } catch(Exception $e) {
            $error = TRUE;
            $errorMessage = $e->getMessage();
        }
    }

    ///////////////////////
    // UPGRADE RO V2.0.3
    ///////////////////////

    if ($common->getSetting("version") == "2.0.2") {
        try {
            $common->updateSetting("version", $thisVersion);
            $common->updateSetting("patch", "");
        } catch(Exception $e) {
            $error = TRUE;
            $errorMessage = $e->getMessage();
        }
    }

    ///////////////////////
    // UPGRADE TO V2.0.4
    ///////////////////////

    if ($common->getSetting("version") == "2.0.3") {
        try {
            // Change tables containing datetime data to datetime.
            if ($settings::db_driver != "xml") {

                // Add indexes to MySQL tables
                if ($settings::db_driver == "mysql") {
                    $stmts = array('CREATE INDEX adsb_positions_message_flight_idx
                                    ON adsb_positions (flight, message DESC);',

                                   'CREATE UNIQUE INDEX adsb_flights_flight_key
                                    ON adsb_flights (flight);',

                                   'CREATE UNIQUE INDEX adsb_aircraft_icao_key
                                    ON adsb_aircraft (icao);')
                }
                elseif ($settings::db_driver == "sqlite") {
                    $stmts = array('CREATE INDEX IF NOT EXISTS adsb_positions_message_flight_idx
                                    ON adsb_positions (flight, message DESC);',

                                   'CREATE UNIQUE INDEX IF NOT EXISTS adsb_flights_flight_key
                                    ON adsb_flights (flight);',

                                   'CREATE UNIQUE INDEX IF NOT EXISTS adsb_aircraft_icao_key
                                    ON adsb_aircraft (icao);')
                }
                elseif ($settings::db_driver == "pgsql") {
                    $stmts = array('CREATE INDEX CONCURRENTLY adsb_positions_message_flight_idx
                                    ON adsb_positions (flight, message DESC);',

                                   'CREATE UNIQUE INDEX CONCURRENTLY adsb_flights_flight_key
                                    ON adsb_flights (flight);',

                                   'CREATE UNIQUE INDEX CONCURRENTLY adsb_aircraft_icao_key
                                    ON adsb_aircraft (icao);')
                }

                $dbh = $common->pdoOpen();
                foreach ($stmts as $stmt) {
                  $sth = $dbh->prepare($stmt);
                  $sth->execute();
                  $sth = NULL;
                }
                $dbh = NULL;
            }

            $common->updateSetting("version", $thisVersion);
            $common->updateSetting("patch", "");
        } catch(Exception $e) {
            $error = TRUE;
            $errorMessage = $e->getMessage();
        }
    }

    require_once('../admin/includes/header.inc.php');

    // Display the instalation wizard.
    if (!$error) {
?>
<h1>ADS-B Receiver Portal Updated</h1>
<p>Your portal has been upgraded to v<?php echo $thisVersion; ?>.</p>
<?php
    } else {
?>
<h1>Error Encountered Upgrading Your ADS-B Receiver Portal</h1>
<p>There was an error encountered when upgrading your portal to v<?php echo $thisVersion; ?>.</p>
<?php echo $errorMessage; ?>
<?php
    }
    require_once('../admin/includes/footer.inc.php');
?>
