-- phpMyAdmin SQL Dump
-- version 4.7.4
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 05, 2017 at 04:13 AM
-- Server version: 10.1.26-MariaDB
-- PHP Version: 7.1.9

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `kantin`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_barang_kadaluarsa` ()  BEGIN
	SELECT nama_barang,tanggal_kadaluarsa
	FROM barang,stock
	WHERE barang.`idbarang`=stock.`idbarang` AND tanggal_kadaluarsa<=NOW();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_beli2` (`p_idbarang` INT, `p_quanty` INT)  BEGIN
/*
algo :
while p_quanty > 0
	# jml = stock terkecil id barang tsb
	# if p_quanty <= jml
		update : stock terlama nya dikurangi - pquanty
		update : p_quanty = 0
	# else
		update : slot terlama di hapus
		update : pquanty - stock terambil
*/	
	
	# setting idtransaksi
	INSERT INTO transaksi (tanggal_transaksi) VALUES (NOW());
	SET @idtransaksi = (	SELECT idtransaksi
				FROM transaksi
				ORDER BY tanggal_transaksi DESC
				LIMIT 0,1);
	INSERT INTO`transaksi_detail` VALUES (@idtransaksi, p_idbarang, p_quanty);
	SET @pquanty = p_quanty;
	#pengurangan barang
	WHILE @pquanty > 0 DO
		SET @jml_sekarang = (	SELECT stok
					FROM `stock`
					WHERE idbarang = p_idbarang
					ORDER BY tanggal_kadaluarsa ASC
					LIMIT 0,1);
		
		IF(@pquanty <= @jml_sekarang)
		THEN
			UPDATE stock
			SET stok = stok - @pquanty
			WHERE idbarang = p_idbarang
			ORDER BY tanggal_kadaluarsa ASC
			LIMIT 1;
			
			SET @pquanty = 0;
			SET @jml_akhir = (	SELECT stok
						FROM `stock`
						WHERE idbarang = p_idbarang
						ORDER BY tanggal_kadaluarsa ASC
						LIMIT 0,1);
			IF(@jml_akhir = 0)
			THEN
				DELETE FROM stock
				WHERE stok = 0;
			END IF;
		ELSE
			SET @idstock_hapus = (	SELECT idstock
						FROM `stock`
						WHERE idbarang = p_idbarang
						ORDER BY tanggal_kadaluarsa ASC
						LIMIT 0,1);
			DELETE FROM stock
			WHERE idstock = @idstock_hapus;
			SET @pquanty = @pquanty - @jml_sekarang;
		END IF;
		
		
	END WHILE;
	
	# pastikan semua stock 0 hilang
	DELETE FROM stock
	WHERE stok = 0;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_beli_barang` (`id` INT(11), `id_barang` INT, `p_quanty` INT)  BEGIN
/*
algo :
setiap pembelian, id transaksi pake idtrans yang maks
while p_quanty > 0
	# jml = stock terkecil id barang tsb
	# if p_quanty <= jml
		update : stock terlama nya dikurangi - pquanty
		update : p_quanty = 0
	# else
		update : slot terlama di hapus
		update : pquanty - stock terambil
*/	
	
	# setting idtransaksi
	/*
	INSERT INTO transaksi (tanggal_transaksi) VALUES (NOW());
	SET @idtransaksi = (	SELECT idtransaksi
				FROM transaksi
				ORDER BY tanggal_transaksi DESC
				LIMIT 0,1);
	*/
	#INSERT INTO`transaksi_detail` VALUES (@idtransaksi, p_idbarang, p_quanty);
	SET @idbarang = (id_barang);
	
	INSERT INTO`transaksi_detail` VALUES (id, @idbarang, p_quanty);
	SET @pquanty = p_quanty;
	#pengurangan barang
	WHILE @pquanty > 0 DO
		SET @jml_sekarang = (	SELECT stok
					FROM `stock`
					WHERE idbarang = @idbarang
					ORDER BY tanggal_kadaluarsa ASC
					LIMIT 0,1);
		
		IF(@pquanty <= @jml_sekarang)
		THEN
			UPDATE stock
			SET stok = stok - @pquanty
			WHERE idbarang = @idbarang
			ORDER BY tanggal_kadaluarsa ASC
			LIMIT 1;
			
			SET @pquanty = 0;
			SET @jml_akhir = (	SELECT stok
						FROM `stock`
						WHERE idbarang = @idbarang
						ORDER BY tanggal_kadaluarsa ASC
						LIMIT 0,1);
			IF(@jml_akhir = 0)
			THEN
				DELETE FROM stock
				WHERE stok = 0;
			END IF;
		ELSE
			SET @idstock_hapus = (	SELECT idstock
						FROM `stock`
						WHERE idbarang = @idbarang
						ORDER BY tanggal_kadaluarsa ASC
						LIMIT 0,1);
			DELETE FROM stock
			WHERE idstock = @idstock_hapus;
			SET @pquanty = @pquanty - @jml_sekarang;
		END IF;
		
		
	END WHILE;
	
	# pastikan semua stock 0 hilang
	DELETE FROM stock
	WHERE stok = 0;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_beli_terbanyak` ()  BEGIN
	SELECT nama_barang,SUM(jumlah) AS Jumlah FROM transaksi_detail,barang,transaksi WHERE transaksi_detail.`idbarang`=barang.`idbarang` AND transaksi.`idtransaksi`=transaksi_detail.`idtransaksi` GROUP BY transaksi_detail.`idbarang` ORDER BY Jumlah DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_buka_tutup` ()  BEGIN
	SET @Status = (SELECT kondisi FROM buka_tutup);
	IF(@Status = "1")
	THEN UPDATE buka_tutup SET kondisi = "0";
	ELSE
	UPDATE buka_tutup SET kondisi = "1";
	END IF;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_daftar_barang` ()  BEGIN
	SELECT barang.`idbarang`, nama_barang AS Barang, harga_beli AS Beli, harga_jual AS Harga, SUM(stok) AS Jumlah 
	FROM barang,stock 
	WHERE barang.`idbarang`=stock.`idbarang`
	GROUP BY barang.`idbarang`
	UNION
	SELECT barang.idbarang, nama_barang, harga_beli, harga_jual, 0
	FROM barang WHERE NOT EXISTS(SELECT stock.`idbarang`FROM stock WHERE barang.`idbarang`=stock.`idbarang`);
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_hapus_barang` (`p_nama_barang` VARCHAR(32))  BEGIN
	DELETE FROM `barang`
	WHERE `idbarang` = p_nama_barang OR `nama_barang` = p_nama_barang;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_hapus_kadaluarsa` ()  BEGIN
    DELETE FROM stock WHERE idstock IN (SELECT idstock
					    FROM barang
	                                    WHERE barang.`idbarang`=stock.`idbarang` 
	                                    AND tanggal_kadaluarsa<=NOW());
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_harga` ()  BEGIN
	set @idtrans = (select idtransaksi 
				from transaksi
				order by tanggal_transaksi desc
				limit 0,1);
	SELECT transaksi_detail.idbarang, nama_barang, (jumlah*harga_jual) AS harga
	FROM transaksi_detail JOIN barang ON barang.idbarang = transaksi_detail.idbarang
	WHERE idtransaksi = @idtrans;
	insert into transaksi(tanggal_transaksi) values (now());
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_harga_total` ()  BEGIN
	SET @id = (SELECT MAX(idtransaksi) FROM transaksi);
	
	SELECT SUM(harga_jual*jumlah) as total
	FROM barang,transaksi_detail
	WHERE idtransaksi = @id AND barang.`idbarang`= transaksi_detail.`idbarang`;
	
	update transaksi set tanggal_transaksi=now() where idtransaksi=@id;
	
	INSERT INTO transaksi(tanggal_transaksi) VALUES (NOW());
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_id_transaksi` ()  BEGIN
	SET @Max = (SELECT MAX(idtransaksi) FROM transaksi);
	
	IF(@Max)
	THEN 
		SET @Maxbar = (SELECT MAX(idbarang) FROM transaksi_detail WHERE idtransaksi = @Max);
		
		IF(@Maxbar)
		THEN SELECT MAX(idtransaksi) AS id, 1 AS val FROM transaksi;
		ELSE
		SELECT MAX(idtransaksi) AS id, 0 AS val FROM transaksi;
		END IF;
		
	ELSE 
		CALL sp_insert_id_transaksi();
		SET @Maxbar = (SELECT MAX(idbarang) FROM transaksi_detail WHERE idtransaksi = @Max);
		
		IF(@Maxbar)
		THEN SELECT MAX(idtransaksi) AS id, 1 AS val FROM transaksi;
		ELSE
		SELECT MAX(idtransaksi) AS id, 0 AS val FROM transaksi;
		END IF;
		
	END IF;
	
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_id_transaksi` ()  BEGIN
	insert into transaksi(tanggal_transaksi) values (NOW());
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_laporan_keuntungan` (`bulan` INT)  BEGIN
	SET @Beli = (SELECT if(SUM(jumlah*harga_beli) is not null, SUM(jumlah*harga_beli), 0) FROM transaksi_detail,barang,transaksi WHERE transaksi_detail.`idbarang`=barang.`idbarang` AND transaksi.`idtransaksi`=transaksi_detail.`idtransaksi` AND EXTRACT(MONTH FROM transaksi.`tanggal_transaksi`)=bulan); 
	SET @Jual = (SELECT if(SUM(jumlah*harga_jual) is not null, SUM(jumlah*harga_jual), 0) FROM transaksi_detail,barang,transaksi WHERE transaksi_detail.`idbarang`=barang.`idbarang` AND transaksi.`idtransaksi`=transaksi_detail.`idtransaksi` AND EXTRACT(MONTH FROM transaksi.`tanggal_transaksi`)=bulan);
	SELECT @Beli AS Pembelian, @Jual AS Penjualan,FLOOR(@Jual-@Beli) AS Keuntungan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_laporan_pembelian` (`bulan` INT)  BEGIN
	select sum(jumlah*harga_beli) as Pembelian from transaksi_detail,barang,transaksi where transaksi_detail.`idbarang`=barang.`idbarang` and transaksi.`idtransaksi`=transaksi_detail.`idtransaksi` and extract(month from transaksi.`tanggal_transaksi`)=bulan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_laporan_penjualan` (`bulan` INT)  BEGIN
	select if(sum(jumlah*harga_jual) is not null, SUM(jumlah*harga_jual), 0) as Penjualan from transaksi_detail,barang,transaksi where transaksi_detail.`idbarang`=barang.`idbarang` and transaksi.`idtransaksi`=transaksi_detail.`idtransaksi` and extract(month from transaksi.`tanggal_transaksi`)=bulan;
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_list_barang` ()  BEGIN
	SELECT * FROM barang;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_notifikasi` ()  BEGIN
	
	SET @Kadaluarsa = (SELECT IF(COUNT(nama_barang) IS NOT NULL,COUNT(nama_barang), 0) AS Jumlah
	FROM barang,stock
	WHERE barang.`idbarang`=stock.`idbarang` AND tanggal_kadaluarsa<=NOW());	      
	
	 SET @Tipis = (SELECT COUNT(tab.total) FROM (SELECT SUM(stok) AS total FROM stock GROUP BY idbarang) AS tab WHERE tab.total<10);
		      
	SELECT @Kadaluarsa AS kadaluarsa , @Tipis AS tipis;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_restock_barang` (`id` INT, `jumlah` INT, `kadaluarsa` DATETIME)  BEGIN
	INSERT INTO stock(idbarang,stok,tanggal_beli,tanggal_kadaluarsa) VALUES (id,jumlah,now(),kadaluarsa);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_stok_tipis` ()  BEGIN
	SELECT barang.`idbarang`, barang.`nama_barang`, IF(SUM(stock.`stok`) IS NOT NULL, SUM(stock.`stok`), 0) AS Stok
	FROM barang LEFT JOIN stock ON barang.`idbarang` = stock.`idbarang`
	GROUP BY barang.`idbarang`
	HAVING SUM(stock.`stok`) < 10;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tambah_barang` (`p_nama_barang` VARCHAR(32), `p_hbeli` INT, `p_hjual` INT)  BEGIN
	INSERT INTO `barang`(`nama_barang`,`harga_beli`,`harga_jual`) VALUES (p_nama_barang, p_hbeli, p_hjual);
	
    END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `Min_stock_id` (`idbrg` INT) RETURNS INT(11) BEGIN
	
	return (SELECT MIN(idstock) FROM stock WHERE idbarang=idbrg);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Stok_barang` (`id` INT) RETURNS INT(11) BEGIN
	return (SELECT stok FROM stock WHERE idstock=id);
    END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `barang`
--

CREATE TABLE `barang` (
  `idbarang` int(11) NOT NULL COMMENT 'id barang/ jajanan',
  `nama_barang` varchar(32) NOT NULL COMMENT 'nama barang',
  `harga_beli` int(11) NOT NULL COMMENT 'harga barang',
  `harga_jual` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `barang`
--

INSERT INTO `barang` (`idbarang`, `nama_barang`, `harga_beli`, `harga_jual`) VALUES
(1, 'Tahu isi', 1300, 1500),
(2, 'Kacang', 800, 1000),
(3, 'Nasi daun', 7400, 7500),
(4, 'Nasi kuning', 7300, 7500),
(7, 'Aqua', 1500, 2000),
(8, 'Mie Boyki', 250, 500),
(9, 'nasi jamur', 5000, 6500),
(10, 'Jus jeruk', 1500, 3000);

-- --------------------------------------------------------

--
-- Table structure for table `buka_tutup`
--

CREATE TABLE `buka_tutup` (
  `Kondisi` varchar(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `buka_tutup`
--

INSERT INTO `buka_tutup` (`Kondisi`) VALUES
('0');

-- --------------------------------------------------------

--
-- Table structure for table `stock`
--

CREATE TABLE `stock` (
  `idstock` int(11) NOT NULL,
  `idbarang` int(11) NOT NULL,
  `stok` int(11) NOT NULL DEFAULT '0' COMMENT 'stok barang',
  `tanggal_beli` datetime NOT NULL COMMENT 'tanggal saat beli',
  `tanggal_kadaluarsa` datetime NOT NULL COMMENT 'tanggal kadaluarsa'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `stock`
--

INSERT INTO `stock` (`idstock`, `idbarang`, `stok`, `tanggal_beli`, `tanggal_kadaluarsa`) VALUES
(3, 1, 15, '2015-05-19 10:53:54', '2015-11-06 17:00:00'),
(6, 10, 13, '2015-05-20 09:32:27', '2015-05-23 17:00:00'),
(7, 8, 13, '2015-05-20 17:33:50', '2015-05-23 17:00:00'),
(8, 1, 2, '2015-05-20 17:34:02', '2015-06-23 17:00:00'),
(11, 3, 4, '2015-05-20 22:48:57', '2015-04-23 17:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `transaksi`
--

CREATE TABLE `transaksi` (
  `idtransaksi` int(11) NOT NULL,
  `tanggal_transaksi` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `transaksi`
--

INSERT INTO `transaksi` (`idtransaksi`, `tanggal_transaksi`) VALUES
(1, '2015-05-20 23:06:48'),
(2, '2015-05-20 23:07:00'),
(3, '2015-05-20 23:15:57'),
(4, '2017-10-05 08:24:57'),
(5, '2017-10-05 09:08:55'),
(6, '2017-10-05 09:08:55');

-- --------------------------------------------------------

--
-- Table structure for table `transaksi_detail`
--

CREATE TABLE `transaksi_detail` (
  `idtransaksi` int(11) NOT NULL,
  `idbarang` int(11) NOT NULL,
  `jumlah` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `transaksi_detail`
--

INSERT INTO `transaksi_detail` (`idtransaksi`, `idbarang`, `jumlah`) VALUES
(1, 8, 3),
(2, 1, 2),
(3, 8, 3),
(4, 3, 1),
(5, 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `id` int(2) DEFAULT NULL,
  `username` varchar(32) DEFAULT NULL,
  `password` varchar(32) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `username`, `password`) VALUES
(1, 'adminkantin', 'ibukantin');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `barang`
--
ALTER TABLE `barang`
  ADD PRIMARY KEY (`idbarang`);

--
-- Indexes for table `stock`
--
ALTER TABLE `stock`
  ADD PRIMARY KEY (`idstock`),
  ADD KEY `FKEY1` (`idbarang`);

--
-- Indexes for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`idtransaksi`);

--
-- Indexes for table `transaksi_detail`
--
ALTER TABLE `transaksi_detail`
  ADD KEY `FKEY_DETAIL_1` (`idtransaksi`),
  ADD KEY `FK_IDBARANG` (`idbarang`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `barang`
--
ALTER TABLE `barang`
  MODIFY `idbarang` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id barang/ jajanan', AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `stock`
--
ALTER TABLE `stock`
  MODIFY `idstock` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `idtransaksi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `stock`
--
ALTER TABLE `stock`
  ADD CONSTRAINT `FKEY1` FOREIGN KEY (`idbarang`) REFERENCES `barang` (`idbarang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `transaksi_detail`
--
ALTER TABLE `transaksi_detail`
  ADD CONSTRAINT `FKEY_DETAIL_1` FOREIGN KEY (`idtransaksi`) REFERENCES `transaksi` (`idtransaksi`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_IDBARANG` FOREIGN KEY (`idbarang`) REFERENCES `barang` (`idbarang`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
