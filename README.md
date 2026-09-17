# Public Mobile SIP Sistem Absensi

Repository ini digunakan untuk pengembangan **Public Mobile SIP Sistem Absensi** PT Selada Indonesia Produktif.

Public Mobile SIP Sistem Absensi merupakan aplikasi yang digunakan sebagai perangkat absensi bersama pada lingkungan perusahaan. Aplikasi ini memungkinkan pegawai melakukan proses absensi menggunakan kartu NFC yang telah terhubung dengan data pegawai pada sistem.

---

## Fitur Utama

### Public Mobile App

- Absensi menggunakan kartu NFC
- Pembacaan identitas pegawai berdasarkan kartu NFC
- Check In dan Check Out pegawai
- Pencatatan waktu kehadiran
- Pengambilan informasi lokasi perangkat saat proses absensi
- Pemilihan lokasi/cabang absensi
- Dukungan proses absensi pada perangkat bersama

---

## Komponen Sistem

Public Mobile SIP Sistem Absensi terintegrasi dengan beberapa komponen pendukung, yaitu:

- **NFC Reader**, digunakan untuk membaca kartu identitas pegawai saat proses absensi.
- **GPS Location**, digunakan untuk memperoleh informasi lokasi perangkat ketika proses absensi dilakukan.
- **Backend Sistem Absensi**, digunakan untuk menyimpan dan mengelola data kehadiran pegawai.

---

## Branch Strategy

| Branch | Fungsi |
|---------|--------|
| `main` | Menyimpan versi aplikasi yang stabil. |
| `develop` | Branch utama untuk proses pengembangan. |
| `feature/*` | Digunakan untuk pengembangan fitur baru. |
| `hotfix/*` | Digunakan untuk perbaikan bug yang bersifat mendesak (jika diperlukan). |

---

## Development Workflow

```text
feature/*
   │
   ▼
develop
   │
   ▼
main
