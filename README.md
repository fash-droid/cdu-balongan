# Keandalan dan Optimasi Pemeliharaan CDU

**Crude Distillation Unit, Refinery Unit VI Pertamina Balongan, Unit 11**

Aplikasi web untuk analisis keandalan dan optimasi pemeliharaan **Crude Distillation
Unit (CDU) Recovery RDMP Refinery Unit VI Pertamina Balongan, Unit 11**.

Aplikasi ini adalah penerjemahan skrip MATLAB `CDU_PdM_Balongan.m` (v3.0) menjadi
aplikasi web interaktif, ditambah tiga kapabilitas baru:

1. **Diagram RBD interaktif**: klik satu blok untuk melihat parameter Weibull dan
   kurva keandalannya; pilih beberapa blok sekaligus untuk menghitung keandalan
   gabungan seketika dengan logika seri/paralel yang benar.
2. **Optimasi biaya-keandalan multi-objektif (NSGA-II)**: Pareto front antara biaya
   pemeliharaan tahunan dan ketersediaan sistem, memakai biaya SAP yang sebenarnya.
   Dapat dijalankan untuk seluruh CDU, satu Functional System, atau tag pilihan.
3. **Pencarian titik optimal bersumbu tegak ganda**: laju biaya dan keandalan pada
   satu grafik terhadap waktu, lengkap dengan rekomendasi bernalar yang menguji
   kelayakan tugas lebih dahulu sebelum mengoptimasi (lihat bagian 4).

---

## 1. Menjalankan aplikasi

### Cara A. Docker, satu perintah

```bash
docker compose up --build
```

Buka **http://localhost:8080**. Dokumentasi API tersedia di
http://localhost:8000/api/docs.

### Cara B. Manual, dua terminal

**Terminal 1, backend**

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

**Terminal 2, frontend**

```bash
cd frontend
npm install
npm run dev
```

Buka **http://localhost:5173**. Vite mem-proxy `/api` ke `http://127.0.0.1:8000`;
ubah target lewat `VITE_API_TARGET` bila backend berjalan di port lain:

```bash
VITE_API_TARGET=http://127.0.0.1:8010 npm run dev
```

Kebutuhan minimum: **Python 3.11+** dan **Node.js 20+**.

---

## 2. Cara memakai

1. Buka halaman **Data dan unggah**, tarik berkas Excel ekspor SAP ke area unggah.
   Jenis berkas dideteksi otomatis dari **nama kolom**, bukan dari nama berkas:
   - berkas **notifikasi** dikenali dari kolom `Notifictn type` dan mengaktifkan
     seluruh analisis keandalan;
   - berkas **order atau biaya** dikenali dari kolom `TotalPlnndCosts` dan
     mengaktifkan modul optimasi biaya.

   Keduanya boleh diunggah sekaligus, dalam urutan apa pun.
2. Analisis berjalan otomatis. Kartu KPI dan tabel kualitas data langsung terisi.
3. Telusuri modul lewat sidebar. Ubah metode lewat tombol **Pengaturan metode**
   di kanan atas, lalu tekan **Terapkan dan hitung ulang**.
4. Ekspor hasil lewat tombol **CSV** atau **Excel lengkap** pada tiap kartu.

Berkas contoh tersedia di `data/`.

---

## 3. Isi tiap modul

| Halaman | Modul MATLAB | Yang dihitung |
|---|---|---|
| Data dan unggah | A | Kualitas data, rekap M1/M2/M3, jendela pengamatan `T_obs` |
| Keandalan peralatan | B | MTBF, laju kegagalan, gagal/tahun, Pareto 80/20 |
| Functional System | B2, B3, B4 | Rekap per FS, peta panas FS × kelas, Pareto per FS |
| Weibull dan tren | C, C2, C3, D | Weibull per kelas/FS/equipment, kredibilitas Bühlmann, uji Laplace |
| Diagram RBD | E, E1 sampai E4 | Diagram interaktif, R(t), umur keandalan, ketersediaan |
| Monte Carlo | F | Ketersediaan tahunan (mean, P10, P50, P90), downtime |
| Interval pemeliharaan | G | Interval optimal `τ*` Barlow dan Hunter, kurva untuk peralatan pilihan |
| Biaya dan keandalan | baru | Titik optimal bersumbu ganda, Pareto front NSGA-II per lingkup |
| Rekomendasi RCM | J | Matriks risiko, strategi CBM/TBM/RTF, jack-knife, suku cadang |
| Metodologi | tidak ada | Rumus tiap modul dan 19 rujukan standar serta pustaka |

### Cara membaca angka penting

- **`T_obs`**: periode surveilans ISO 14224, yaitu `tanggal_akhir − tanggal_awal`,
  **bukan** jarak antar-kejadian. Mode `cutoff` (default) memakai tanggal terakhir di
  seluruh berkas (tanggal ekspor SAP); mode `lastevent` memakai kejadian unit terakhir.
- **`MTBF`**: `T_obs / n_CM`, dengan `n_CM` = jumlah notifikasi M1 + M2 per tag.
- **`A_inh` vs `A_op`**: selisih keduanya adalah waktu yang hilang karena menunggu
  suku cadang, izin kerja, dan penjadwalan (MDT), *bukan* karena lamanya pekerjaan
  bengkel (MTTR). Ini biasanya temuan paling penting.
- **`R(1 tahun) ≈ 0`** benar, bukan galat: itu peluang sistem melewati setahun penuh
  *tanpa satu pun* kegagalan. Untuk indikator tahunan gunakan `A_op` dan ekspektasi
  jumlah kegagalan.
- **Penghematan PM 0%** juga benar: ketika `β ≈ 1` (kegagalan acak), penggantian
  terjadwal tidak menurunkan laju kegagalan sehingga tidak ada yang bisa dihemat.

---

## 4. Pencarian interval optimal

Halaman **Interval pemeliharaan** dan **Biaya dan keandalan** memuat tiga
kemampuan analisis interval.

### Pemilihan peralatan pada kurva biaya

Halaman Interval pemeliharaan tidak lagi terbatas pada bad actor tiap Functional
System. Panel pemilih memungkinkan Anda memilih peralatan mana pun yang memiliki
riwayat kegagalan, sampai 24 tag sekaligus, lalu setiap tag mendapat kurva laju
biaya terhadap intervalnya sendiri. Rentang interval mengikuti modul G, yaitu
0,05η sampai 3η, agar nilai τ\* sebanding dengan tabel yang sudah tervalidasi.

### Grafik titik optimal bersumbu tegak ganda

| Sumbu | Besaran | Rumus | Rujukan |
|---|---|---|---|
| mendatar | interval penggantian τ (hari) | variabel keputusan | |
| tegak kiri | laju biaya pemeliharaan tahunan | `C(τ) = [Cp·R(τ) + Cf·(1−R(τ))] / ∫₀^τ R(t)dt` | Barlow & Hunter (1960) |
| tegak kanan | keandalan pada saat penggantian | `R(τ) = exp(−(τ/η)^β)` | Rausand & Høyland |
| tegak kanan | ketersediaan operasional | `λ_eff(τ) = [1−R(τ)] / ∫₀^τ R(t)dt`, lalu `A_op = MTBF_eff/(MTBF_eff + MDT)` | Barlow & Proschan; ISO 14224 |

Tiga titik ditandai pada grafik:

1. **Titik biaya minimum τ\*** yaitu interval paling ekonomis.
2. **Titik target keandalan τ_R** yaitu interval terpanjang yang keandalannya
   masih memenuhi batas minimum, dihitung analitik sebagai
   `τ_R = η·(−ln R_target)^(1/β)` (Ebeling). Target dapat diatur dari 0,50
   sampai 0,99 lewat penggeser.
3. **Garis run to failure** yaitu laju biaya bila tidak ada jadwal sama sekali.

Analisis tersedia pada dua lingkup. Untuk **satu peralatan**, seluruh besaran
memakai parameter Weibull tag itu sendiri. Untuk **satu Functional System**,
satu interval yang sama diterapkan pada seluruh peralatan di dalamnya, yaitu
kebijakan *block replacement* (Barlow & Proschan; tinjauan pengelompokan pada
Dekker 1996). Pilihan ini bukan penyederhanaan: pada kilang, satu jendela
berhenti memang dipakai bersama oleh seluruh peralatan dalam satu sistem.
Keandalan dan ketersediaan sistem digabung memakai logika seri-paralel RBD.

### Urutan penalaran rekomendasi

Rekomendasi tidak langsung mengambil titik biaya minimum. Urutannya mengikuti
SAE JA1011, yaitu **uji kelayakan tugas lebih dahulu, baru optimasi**:

1. **Apakah penggantian terjadwal berlaku?**
   `β < 0,90` berarti pola kegagalan dini, sehingga penggantian mengembalikan
   komponen ke daerah kegagalan dini dan menaikkan laju kegagalan.
   `β ≈ 1` berarti laju kegagalan konstan, sehingga komponen baru secara
   statistik identik dengan komponen terpakai dan penggantian tidak mengubah apa
   pun. Pada kedua kondisi ini tugas **tidak berlaku** dan tidak boleh
   dijadwalkan, berapa pun nilai τ_R yang muncul di grafik. Nilai τ_R tetap
   berguna sebagai interval inspeksi atau ambang pemantauan kondisi.
   Hanya `β ≥ 1,20` yang menandakan ada umur aus yang dapat dikenali.
2. **Apakah manfaat ekonominya cukup?** Bila penghematan di bawah ambang, atau
   kurva biaya tidak punya minimum di dalam rentang, jadwal tidak dipilih.
3. **Ekonomi atau keandalan yang mengikat?** Bila τ\* lebih pendek daripada τ_R
   keduanya sejalan; bila sebaliknya, interval dipendekkan ke τ_R dan biaya
   tambahannya dihitung.

Pada tingkat sistem, target keandalan **hanya informasi dan tidak mengikat**.
Keandalan sistem pada interval bersama adalah peluang seluruh peralatan lolos
tanpa satu pun kegagalan, sehingga menuntutnya tinggi pada sistem dengan banyak
komponen seri memaksa interval sangat pendek dan justru **menurunkan**
ketersediaan. Untuk horizon panjang, ukuran yang tepat adalah ketersediaan dan
ekspektasi jumlah kegagalan, bukan keandalan.

### Lingkup NSGA-II

Pareto front dapat dijalankan pada tiga lingkup, dan objektif ketersediaannya
menyesuaikan diri:

| Lingkup | Variabel keputusan | Objektif ketersediaan |
|---|---|---|
| Seluruh CDU | seluruh tag jalur RBD yang pernah gagal | A_op gabungan FS-1, FS-2, FS-3 secara seri |
| Per Functional System | tag pada satu FS | A_op FS itu saja |
| Per peralatan | tag pilihan Anda | A_op gabungan seleksi menurut tipe stage masing-masing |

Konsistensi terverifikasi: A_op garis dasar NSGA-II pada lingkup FS-1 sama
dengan nilai modul E sampai 1×10⁻⁹, yaitu 0,801376.

### Temuan pada data contoh

Beberapa hasil yang perlu diketahui saat membaca angkanya:

- **Grid warisan MATLAB terlalu sempit untuk biaya SAP nyata.** Rentang
  0,05η sampai 3η memadai ketika rasio Cf/Cp sekitar 10, tetapi biaya order
  menghasilkan rasio sampai 360 sehingga minimum bergeser ke interval yang
  sangat pendek dan terpotong batas bawah grid. Alat pencari titik optimal
  karena itu memakai grid logaritmik 0,002η sampai pengali η. Karena
  `C(τ) → ∞` saat `τ → 0`, minimum interior selalu ada untuk `Cf > Cp`.
- **Ketiga Functional System berakhir pada "tugas tidak berlaku"** karena β
  wakilnya berada di sekitar atau di bawah satu. Ini konsisten dengan simpulan
  laporan MATLAB bahwa penjadwalan penggantian tidak memberi penghematan.
- **A_op naik ketika interval diperpanjang pada FS-1 dan FS-3** karena keduanya
  didominasi peralatan berpola kegagalan dini. Jadwal penggantian pada kondisi
  ini merugikan dua kali, yaitu menambah biaya sekaligus menurunkan ketersediaan.
- **Target keandalan 0,90 tidak terjangkau pada tingkat FS-1** untuk interval
  mana pun. Perbaikan hanya mungkin lewat penambahan redundansi atau pengurangan
  titik lemah seri, bukan lewat percepatan jadwal.

---

## 5. Robustness terhadap berkas baru

Aplikasi bekerja untuk berkas Excel apa pun selama **nama kolomnya sama**:

- pencocokan nama kolom **case-insensitive** dan tahan spasi ganda/tanda baca
  (memakai kunci normalisasi yang sama dengan `pickcol()` MATLAB);
- sheet dicari berdasarkan kolom wajibnya, nama sheet tidak pernah di-hard-code;
- kolom wajib yang hilang menghasilkan pesan jelas, bukan stack trace;
- kolom nomor SAP (`Notification`, `Order`) dinormalisasi karena ekspor SAP kadang
  menyimpannya sebagai `float64` (`"2102362822.0"`) dan kadang `int64`;
- tanggal diterima sebagai serial Excel, datetime, maupun teks; tanggal tak sah
  dibuang dan dilaporkan pada kartu kualitas data;
- prefix unit (`11-`) adalah parameter, sehingga unit lain pada berkas yang sama
  dapat dianalisis;
- **tidak ada** daftar tag, jumlah baris, atau tanggal yang di-hard-code. Yang
  di-hard-code hanya *struktur domain* (mapping tag→FS, MDT, struktur RBD, β
  workbook) yang memang bukan data variabel, lihat `app/core/fs_mapping.py`.

---

## 6. Pengujian dan validasi numerik

```bash
cd backend
.venv\Scripts\activate
python -m pytest
```

Suite berisi **156 pengujian**: unit test fungsi inti (dibandingkan dengan jawaban
analitik, bukan dengan keluaran kode ini sendiri) dan validasi numerik terhadap
laporan MATLAB.

### Hasil validasi terhadap laporan

| Besaran | Laporan | Aplikasi | Status |
|---|---|---|---|
| `T_obs` mode cutoff | 17.064 jam (711 hari) | 17.064,000 | tepat |
| `T_obs` mode lastevent | 16.992 jam | 16.992,000 | tepat |
| Jumlah tag / kegagalan korektif | 67 / 142 | 67 / 142 | tepat |
| Pembagian FS (tag) | 23 / 19 / 21 / 4 | 23 / 19 / 21 / 4 | tepat |
| `A_inh` FS-1/2/3/gabungan | 0,966 / 0,949 / 0,979 / 0,897 | sama | tepat |
| `A_op` FS-1/2/3/gabungan | 0,801 / 0,888 / 0,924 / 0,658 | sama | tepat |
| `R(t)` pada 1, 7, 30, 90 hari | 16 nilai | cocok | ≤ 0,0015 |
| MTBF F-101 | 1.551 jam (64,6 hari) | sama | tepat |
| β MRR E-114 / P-102A | 0,52 / 1,53 | 0,522 / 1,529 | tepat |
| β final P-102B / F-101 / E-114 | 0,91 / 1,05 / 0,70 | sama | tepat |
| `τ*` P-102B / F-101 / E-114 | 255 / 198 / 211 hari | 255 / 198 / 211 | tepat |
| `betaWorkbook` heater/vessel/exchanger | konstanta laporan | sama | ~3×10⁻¹⁵ |
| Monte Carlo (400 putaran) | 0,784 / 0,889 / 0,914 / 0,638 | 0,776 / 0,886 / 0,912 / 0,628 | ≤ 1,1% |

**Temuan validasi yang menguatkan:** konstanta `betaWorkbook()` pada laporan ternyata
adalah **Crow-AMSAA pada data kelas yang digabung**. Nilai heater, vessel, dan
exchanger direproduksi sampai **presisi mesin (~3×10⁻¹⁵)**, yang sekaligus
memvalidasi `T_obs`, waktu kalender kegagalan, filter unit, penggolongan M1/M2,
mapping tag→kelas, dan rumus Crow-AMSAA.

### Penyimpangan yang diketahui (dilaporkan, bukan disembunyikan)

1. **`R(30 hari)` FS-3: 0,36646 vs 0,368 pada laporan (selisih 0,4%).**
   Laporan menyiratkan β kelas *vessel* = 0,79042, sedangkan MLE yang benar adalah
   **0,78725**. Negatif log-likelihood di 0,78725 lebih kecil (138,53437 vs
   138,53457), jadi nilai aplikasi ini **lebih tepat**. Penyebabnya toleransi bawaan
   `fminbnd` MATLAB (`TolX = 1e-4`) pada permukaan likelihood yang hampir datar
   (ΔNLL hanya 0,0002 untuk Δβ 0,0032). Tiga metode independen, MLE profil,
   `scipy.stats.weibull_min.fit`, dan akar persamaan likelihood analitik, sepakat
   pada 0,78725 dalam **1,2×10⁻⁸**.
2. **β kelas `pump` Crow-AMSAA: 1,27484 vs 1,28281 pada workbook.** Kelas lain cocok
   sampai ~3×10⁻¹⁵, sehingga selisih ini menunjuk perbedaan vintage data pompa pada
   workbook, bukan perbedaan rumus.
3. **Monte Carlo ≤ 1,1%.** Wajar karena aliran bilangan acak NumPy (PCG64) berbeda
   dari Mersenne Twister MATLAB. Nilai analitik `A_op` yang menjadi acuan silang
   cocok tepat, dan seed disetel sehingga hasil aplikasi reprodusibel.

---

## 7. Sistem desain

Gaya visual mengikuti pertamina.com. Nilainya tidak dikira kira, melainkan
diambil dari gaya terhitung (computed style) situs tersebut:

| Aspek | Nilai | Berkas |
|---|---|---|
| Tipografi | Plus Jakarta Sans 400/500/600/700, tipografi buatan Indonesia | `index.html`, `tailwind.config.js` |
| Warna primer | `#0B2F9F` biru korporat | `tailwind.config.js` (`biru`) |
| Warna aksen | `#E21F23` merah Pertamina | `tailwind.config.js` (`merah`) |
| Netral | skala slate, garis tepi `#E2E8F0` | `index.css` |
| Radius | 4, 6, dan 8 px; tombol berbentuk pill | `tailwind.config.js` |
| Bayangan | nyaris tidak dipakai, pemisah visual berupa garis tepi | `index.css` |
| Ikonografi | ikon garis bergaya Tabler Icons, keluarga yang dipakai pertamina.com | `components/ui/Icon.tsx` |
| Angka | koma sebagai pemisah desimal, titik sebagai pemisah ribuan | `lib/format.ts`, `core/analysis.py` |

Tiga kebiasaan yang sengaja dihindari karena membuat antarmuka terlihat seperti
templat generik:

1. **Emoji sebagai ikon menu.** Seluruh emoji diganti ikon garis SVG dengan
   ketebalan garis dan ukuran yang seragam dengan tipografi.
2. **Tanda hubung panjang (em dash).** Tidak ada satu pun yang tersisa di
   antarmuka maupun pesan backend. Penggantinya adalah titik dua untuk label,
   tanda kurung untuk keterangan tambahan, dan titik atau koma untuk memecah
   kalimat. Tanda hubung biasa tetap dipakai pada penamaan seperti FS-1 dan
   Crow-AMSAA.
3. **Judul berhuruf kapital seluruhnya dengan jarak huruf lebar.** Judul kini
   memakai huruf normal dengan bobot 600, sama seperti pertamina.com.

### Ilustrasi peralatan pada diagram RBD

Setiap blok pada diagram RBD memuat ilustrasi teknis peralatannya: dapur
pemanas berikut stack dan burner, kolom distilasi berikut tray dan skirt,
penukar panas shell and tube berikut bundle dan saddle, pompa sentrifugal
berikut volute dan motor, bejana mendatar berikut saddle dan garis batas
cairan, serta skid injeksi kimia berikut pompa dosis. Semuanya digambar sebagai
SVG di `components/rbd/EquipmentArt.tsx`.

Ilustrasi vektor dipilih, bukan foto, dengan pertimbangan berikut:

* **konsisten** seluruh blok memakai skala, ketebalan garis, dan sudut pandang
  yang sama sehingga diagram terbaca sebagai satu kesatuan, sedangkan foto dari
  sumber berbeda selalu bertabrakan pencahayaan dan sudutnya;
* **tajam** vektor tetap bersih pada ukuran blok 138 px maupun ketika diagram
  diperbesar atau dicetak untuk laporan;
* **ringan dan luring** tidak ada permintaan gambar ke jaringan saat aplikasi
  berjalan, sehingga diagram tetap tampil di jaringan pabrik yang tertutup;
* **bersih secara hak cipta** tidak ada foto kilang milik pihak lain yang perlu
  disertakan di dalam repositori.

Bila Anda memang memiliki foto peralatan CDU milik Pertamina sendiri yang boleh
dipakai, ilustrasi dapat ditukar dengan foto tersebut tanpa mengubah logika
diagram: letakkan berkas gambar di `frontend/public/peralatan/<kelas>.jpg` lalu
ganti isi komponen `EquipmentArt` menjadi elemen `<img>` dengan nama berkas
mengikuti kelas peralatan (`heater`, `column`, `exchanger`, `pump`, `vessel`,
`injection`, `other`).

---

## 8. Arsitektur

```
/backend
 /app
 main.py entrypoint FastAPI + penanganan galat menyeluruh
 /routers endpoint per modul
 /core
 data_loader.py baca & normalisasi Excel (robust)
 fs_mapping.py mapping tag→FS, MDT, kelas, struktur RBD, β workbook
 reliability.py Weibull MRR/MLE, Crow-AMSAA, Laplace, kredibilitas
 rbd.py seri-paralel, R(t), ketersediaan, seleksi dinamis
 montecarlo.py simulasi ketersediaan sistem
 pm_optimization.py age replacement Barlow-Hunter
 cost_optimization.py NSGA-II biaya vs keandalan + agregasi biaya SAP
 criticality.py Risk = PoF × CoF, strategi RCM, jack-knife, spare
 analysis.py orkestrator seluruh modul
 store.py sesi in-memory + serialisasi JSON yang aman
 /config/defaults.py SEMUA parameter dari configDefaults() MATLAB
 /tests 84 pengujian
/frontend
 /src
 /components/rbd diagram RBD interaktif + panel
 /components/charts pembungkus Plotly bertema
 /components/panels kerangka aplikasi, ekspor
 /components/ui kartu, tabel, KPI, toast
 /pages satu halaman per modul
 /api/client.ts klien fetch + pemetaan galat
 /store/useStore.ts state global (zustand)
docker-compose.yml
```

Mengapa backend Python: perhitungan Weibull fitting, Monte Carlo, NSGA-II, dan
Crow-AMSAA menuntut akurasi numerik ilmiah dan pustaka matang (`numpy`, `scipy`,
`pymoo`) yang tidak setara di JavaScript. Seluruh komputasi berat berjalan di
threadpool sehingga event loop tidak terblokir dan antarmuka tidak membeku.

---

## 9. Catatan penting

- **Tidak ada angka yang tidak dihitung dari data.** Setiap nilai pada antarmuka
  berasal dari berkas yang diunggah.
- **Modul sensor sintetis tidak ditampilkan.** Skrip MATLAB memuat modul H (deteksi
  anomali autoencoder) dan I (prediksi RUL LSTM) yang berjalan di atas **sensor
  sintetis**: bukan pengukuran nyata. Modul tersebut sengaja tidak ditampilkan agar
  tidak ada angka yang tampak sebagai hasil pengukuran padahal bukan. Antarmuka
  backend sudah disiapkan agar data historian/DCS yang sebenarnya dapat dipasang
  kemudian.
- **Reprodusibilitas.** Monte Carlo dan NSGA-II memakai seed yang dapat diatur dari
  UI, sehingga hasil yang sama selalu dapat diulang.
- **Penyimpanan sesi bersifat in-memory** (proses tunggal), sesuai penggunaan sebagai
  alat analisis. Untuk penyebaran multi-worker, ganti `app/core/store.py` dengan Redis
  atau basis data.

---

## 10. Referensi

Setiap rumus di kode mencantumkan sumbernya sebagai komentar, dan seluruh daftar
ditampilkan pada halaman **Metodologi** di aplikasi:

ISO 14224:2016 · Abernethy, *The New Weibull Handbook* (5th ed.) · Nelson (1982),
*Applied Life Data Analysis* · Thoman, Bain & Antle (1969) · Crow (1975) &
MIL-HDBK-189 · Ascher & Feingold (1984) · Rausand & Høyland, *System Reliability
Theory* · Barlow & Hunter (1960) · Jardine & Tsang · Blanchard & Fabrycky · Deb,
Pratap, Agarwal & Meyarivan (2002) *NSGA-II* · SAE JA1011/JA1012 · API 580/581 ·
Knights (2001) · OREDA · Bühlmann, *credibility theory* · Ebeling, *An Introduction
to Reliability and Maintainability Engineering* · Barlow & Proschan, *Mathematical
Theory of Reliability* · Dekker (1996), *Applications of maintenance optimisation
models*, Reliability Engineering & System Safety 51(3).
