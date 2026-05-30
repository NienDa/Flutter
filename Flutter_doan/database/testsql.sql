create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- =========================================================
drop table if exists public.nhat_ky_he_thong cascade;
drop table if exists public.thong_bao_he_thong cascade;
drop table if exists public.nguyen_vong_de_tai cascade;
drop table if exists public.yeu_cau_vao_nhom cascade;
drop table if exists public.thanh_vien_nhom cascade;
drop table if exists public.de_tai cascade;
drop table if exists public.nhom_do_an cascade;
drop table if exists public.ghi_danh cascade;
drop table if exists public.lop_do_an cascade;
drop table if exists public.ho_so cascade;

drop type if exists public.trang_thai_de_tai cascade;
drop type if exists public.trang_thai_yeu_cau cascade;
drop type if exists public.trang_thai_thanh_vien cascade;
drop type if exists public.vai_tro_thanh_vien cascade;
drop type if exists public.trang_thai_nhom cascade;
drop type if exists public.trang_thai_ghi_danh cascade;
drop type if exists public.trang_thai_lop_do_an cascade;
drop type if exists public.vai_tro_ung_dung cascade;

drop function if exists public.dat_cap_nhat_luc() cascade;
drop function if exists public.vai_tro_hien_tai() cascade;
drop function if exists public.la_quan_tri_vien() cascade;
drop function if exists public.la_giang_vien_phu_trach_lop(uuid) cascade;
drop function if exists public.la_sinh_vien_da_ghi_danh(uuid) cascade;
drop function if exists public.chua_co_nhom_trong_lop_hien_tai(uuid) cascade;
drop function if exists public.la_thanh_vien_nhom_hien_tai(uuid) cascade;
drop function if exists public.la_nhom_truong_hien_tai(uuid) cascade;
drop function if exists public.sinh_vien_duoc_tao_nhom(uuid) cascade;
drop function if exists public.co_the_xem_ho_so(uuid) cascade;
drop function if exists public.tao_ho_so_nguoi_dung_moi() cascade;
drop function if exists public.bao_ve_ho_so_khi_cap_nhat() cascade;
drop function if exists public.bao_ve_nhom_do_an_khi_cap_nhat() cascade;
drop function if exists public.tu_them_nhom_truong_sau_khi_tao_nhom() cascade;
drop function if exists public.bao_ve_de_tai_khi_cap_nhat() cascade;
drop function if exists public.kiem_tra_nhom_do_an_truoc_khi_them() cascade;
drop function if exists public.kiem_tra_nguyen_vong_truoc_khi_them() cascade;
drop function if exists public.xu_ly_nguyen_vong_sau_khi_cap_nhat() cascade;
drop function if exists public.gui_thong_bao(uuid, text, text, text, text) cascade;
drop function if exists public.ghi_nhat_ky(text, text, uuid, jsonb) cascade;
drop function if exists public.tao_tai_khoan_mau(
  uuid, text, text, text, public.vai_tro_ung_dung, text, text, text, text, text, text
) cascade;

-- =========================================================
-- 1) ENUMS
create type public.vai_tro_ung_dung as enum ('sinh_vien', 'giang_vien', 'quan_tri_vien');

create type public.trang_thai_lop_do_an as enum (
  'ban_nhap',
  'mo_dang_ky',
  'dong_dang_ky',
  'dang_thuc_hien',
  'hoan_thanh',
  'luu_tru'
);

create type public.trang_thai_ghi_danh as enum ('cho_duyet', 'da_duyet', 'tu_choi', 'huy');

create type public.trang_thai_nhom as enum ('dang_tao', 'cho_duyet', 'da_duyet', 'da_khoa', 'da_huy');

create type public.vai_tro_thanh_vien as enum ('nhom_truong', 'thanh_vien');

create type public.trang_thai_thanh_vien as enum ('cho_duyet', 'da_chap_nhan', 'tu_choi', 'da_roi', 'bi_xoa');

create type public.trang_thai_yeu_cau as enum ('cho_duyet', 'da_duyet', 'tu_choi', 'da_huy');

create type public.trang_thai_de_tai as enum (
  'ban_nhap',
  'da_cong_bo',
  'cho_duyet',
  'da_gan_nhom',
  'da_chot',
  'dong',
  'luu_tru'
);


-- BẢNG CHÍNH
-- =========================================================
create table public.ho_so (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  ho_ten text not null,
  vai_tro public.vai_tro_ung_dung not null default 'sinh_vien',
  ma_sinh_vien text unique,
  ma_giang_vien text unique,
  lop_hanh_chinh text,
  khoa text,
  nganh text,
  so_dien_thoai text,
  anh_dai_dien_url text,
  dang_hoat_dong boolean not null default true,
  tao_luc timestamptz not null default now(),
  cap_nhat_luc timestamptz not null default now()
);

create table public.lop_do_an (
  id uuid primary key default extensions.gen_random_uuid(),
  giang_vien_id uuid not null references public.ho_so(id) on delete restrict,
  ma_lop text not null unique,
  ten_lop text not null,
  hoc_ky text not null,
  ten_mon_hoc text not null,
  mo_ta text,
  so_thanh_vien_toi_thieu integer not null default 1 check (so_thanh_vien_toi_thieu >= 1),
  so_thanh_vien_toi_da integer not null default 5 check (so_thanh_vien_toi_da >= 1),
  mo_dang_ky_luc timestamptz,
  dong_dang_ky_luc timestamptz,
  mo_chon_de_tai_luc timestamptz,
  dong_chon_de_tai_luc timestamptz,
  cho_phep_sinh_vien_tao_nhom boolean not null default true,
  can_giang_vien_duyet boolean not null default true,
  trang_thai public.trang_thai_lop_do_an not null default 'ban_nhap',
  tao_luc timestamptz not null default now(),
  cap_nhat_luc timestamptz not null default now(),
  constraint ck_lop_do_an_so_luong_tv check (so_thanh_vien_toi_thieu <= so_thanh_vien_toi_da),
  constraint ck_lop_do_an_moc_dang_ky check (
    mo_dang_ky_luc is null or dong_dang_ky_luc is null or mo_dang_ky_luc < dong_dang_ky_luc
  ),
  constraint ck_lop_do_an_moc_chon_de_tai check (
    mo_chon_de_tai_luc is null or dong_chon_de_tai_luc is null or mo_chon_de_tai_luc < dong_chon_de_tai_luc
  )
);

create table public.ghi_danh (
  id uuid primary key default extensions.gen_random_uuid(),
  lop_do_an_id uuid not null references public.lop_do_an(id) on delete cascade,
  sinh_vien_id uuid not null references public.ho_so(id) on delete cascade,
  trang_thai public.trang_thai_ghi_danh not null default 'da_duyet',
  ghi_danh_luc timestamptz not null default now(),
  cap_nhat_luc timestamptz not null default now(),
  duyet_boi uuid references public.ho_so(id) on delete set null,
  duyet_luc timestamptz,
  ghi_chu text,
  unique (lop_do_an_id, sinh_vien_id)
);

create table public.nhom_do_an (
  id uuid primary key default extensions.gen_random_uuid(),
  lop_do_an_id uuid not null references public.lop_do_an(id) on delete cascade,
  ten_nhom text not null,
  mo_ta text,
  tao_boi uuid not null references public.ho_so(id) on delete restrict,
  trang_thai public.trang_thai_nhom not null default 'dang_tao',
  duyet_boi uuid references public.ho_so(id) on delete set null,
  duyet_luc timestamptz,
  khoa_luc timestamptz,
  tao_luc timestamptz not null default now(),
  cap_nhat_luc timestamptz not null default now(),
  unique (lop_do_an_id, ten_nhom),
  unique (id, lop_do_an_id)
);

create table public.thanh_vien_nhom (
  id uuid primary key default extensions.gen_random_uuid(),
  lop_do_an_id uuid not null,
  nhom_id uuid not null,
  sinh_vien_id uuid not null references public.ho_so(id) on delete cascade,
  vai_tro public.vai_tro_thanh_vien not null default 'thanh_vien',
  trang_thai public.trang_thai_thanh_vien not null default 'da_chap_nhan',
  tham_gia_luc timestamptz not null default now(),
  moi_boi uuid references public.ho_so(id) on delete set null,
  ghi_chu text,
  foreign key (nhom_id, lop_do_an_id) references public.nhom_do_an(id, lop_do_an_id) on delete cascade,
  foreign key (lop_do_an_id, sinh_vien_id) references public.ghi_danh(lop_do_an_id, sinh_vien_id) on delete cascade,
  unique (nhom_id, sinh_vien_id)
);

create table public.de_tai (
  id uuid primary key default extensions.gen_random_uuid(),
  lop_do_an_id uuid not null references public.lop_do_an(id) on delete cascade,
  giang_vien_id uuid not null references public.ho_so(id) on delete restrict,
  nhom_id uuid references public.nhom_do_an(id) on delete set null,
  ma_de_tai text not null,
  ten_de_tai text not null,
  mo_ta text,
  muc_tieu text,
  yeu_cau text,
  cong_nghe text,
  san_pham_ban_giao text,
  so_thanh_vien_toi_thieu integer not null default 1 check (so_thanh_vien_toi_thieu >= 1),
  so_thanh_vien_toi_da integer not null default 5 check (so_thanh_vien_toi_da >= 1),
  trang_thai public.trang_thai_de_tai not null default 'ban_nhap',
  tao_boi uuid references public.ho_so(id) on delete set null,
  duyet_boi uuid references public.ho_so(id) on delete set null,
  cong_bo_luc timestamptz,
  tao_luc timestamptz not null default now(),
  cap_nhat_luc timestamptz not null default now(),
  unique (lop_do_an_id, ma_de_tai),
  unique (lop_do_an_id, nhom_id),
  constraint ck_de_tai_so_luong_tv check (so_thanh_vien_toi_thieu <= so_thanh_vien_toi_da)
);

create table public.nguyen_vong_de_tai (
  id uuid primary key default extensions.gen_random_uuid(),
  lop_do_an_id uuid not null,
  nhom_id uuid not null,
  de_tai_id uuid not null references public.de_tai(id) on delete cascade,
  thu_tu integer not null default 1 check (thu_tu >= 1),
  loi_nhan text,
  trang_thai public.trang_thai_yeu_cau not null default 'cho_duyet',
  tao_boi uuid not null references public.ho_so(id) on delete cascade,
  duyet_boi uuid references public.ho_so(id) on delete set null,
  duyet_luc timestamptz,
  tao_luc timestamptz not null default now(),
  foreign key (nhom_id, lop_do_an_id) references public.nhom_do_an(id, lop_do_an_id) on delete cascade,
  unique (lop_do_an_id, nhom_id, de_tai_id)
);

create table public.yeu_cau_vao_nhom (
  id uuid primary key default extensions.gen_random_uuid(),
  lop_do_an_id uuid not null,
  nhom_id uuid not null,
  sinh_vien_id uuid not null references public.ho_so(id) on delete cascade,
  loi_nhan text,
  trang_thai public.trang_thai_yeu_cau not null default 'cho_duyet',
  xu_ly_boi uuid references public.ho_so(id) on delete set null,
  xu_ly_luc timestamptz,
  tao_luc timestamptz not null default now(),
  foreign key (nhom_id, lop_do_an_id) references public.nhom_do_an(id, lop_do_an_id) on delete cascade,
  foreign key (lop_do_an_id, sinh_vien_id) references public.ghi_danh(lop_do_an_id, sinh_vien_id) on delete cascade
);

create table public.thong_bao_he_thong (
  id uuid primary key default extensions.gen_random_uuid(),
  nguoi_nhan_id uuid not null references public.ho_so(id) on delete cascade,
  tieu_de text not null,
  noi_dung text not null,
  loai text not null default 'he_thong',
  duong_dan text,
  da_doc boolean not null default false,
  tao_boi uuid references public.ho_so(id) on delete set null,
  tao_luc timestamptz not null default now()
);

create table public.nhat_ky_he_thong (
  id uuid primary key default extensions.gen_random_uuid(),
  nguoi_thuc_hien_id uuid references public.ho_so(id) on delete set null,
  hanh_dong text not null,
  loai_doi_tuong text not null,
  doi_tuong_id uuid,
  du_lieu jsonb not null default '{}'::jsonb,
  tao_luc timestamptz not null default now()
);

-- =========================================================
-- HÀM 
create or replace function public.dat_cap_nhat_luc()
returns trigger
language plpgsql
as $$
begin
  new.cap_nhat_luc = now();
  return new;
end;
$$;

create or replace function public.vai_tro_hien_tai()
returns public.vai_tro_ung_dung
language sql
stable
security definer
set search_path = public
as $$
  select h.vai_tro
  from public.ho_so h
  where h.id = auth.uid()
  limit 1;
$$;

create or replace function public.la_quan_tri_vien()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.ho_so h
    where h.id = auth.uid()
      and h.vai_tro = 'quan_tri_vien'
  );
$$;

create or replace function public.la_giang_vien_phu_trach_lop(p_lop_do_an_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.lop_do_an l
    where l.id = p_lop_do_an_id
      and l.giang_vien_id = auth.uid()
  );
$$;

create or replace function public.la_sinh_vien_da_ghi_danh(p_lop_do_an_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.ghi_danh g
    where g.lop_do_an_id = p_lop_do_an_id
      and g.sinh_vien_id = auth.uid()
      and g.trang_thai = 'da_duyet'
  );
$$;

create or replace function public.chua_co_nhom_trong_lop_hien_tai(p_lop_do_an_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1
    from public.thanh_vien_nhom tv
    where tv.lop_do_an_id = p_lop_do_an_id
      and tv.sinh_vien_id = auth.uid()
      and tv.trang_thai = 'da_chap_nhan'
  );
$$;

create or replace function public.la_thanh_vien_nhom_hien_tai(p_nhom_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.thanh_vien_nhom tv
    where tv.nhom_id = p_nhom_id
      and tv.sinh_vien_id = auth.uid()
      and tv.trang_thai = 'da_chap_nhan'
  );
$$;

create or replace function public.la_nhom_truong_hien_tai(p_nhom_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.thanh_vien_nhom tv
    where tv.nhom_id = p_nhom_id
      and tv.sinh_vien_id = auth.uid()
      and tv.vai_tro = 'nhom_truong'
      and tv.trang_thai = 'da_chap_nhan'
  );
$$;

create or replace function public.lop_do_an_dang_mo_dang_ky(p_lop_do_an_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.lop_do_an l
    where l.id = p_lop_do_an_id
      and l.trang_thai = 'mo_dang_ky'
      and (l.mo_dang_ky_luc is null or l.mo_dang_ky_luc <= now())
      and (l.dong_dang_ky_luc is null or l.dong_dang_ky_luc >= now())
  );
$$;

create or replace function public.lop_do_an_dang_mo_chon_de_tai(p_lop_do_an_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.lop_do_an l
    where l.id = p_lop_do_an_id
      and l.trang_thai in ('mo_dang_ky', 'dang_thuc_hien')
      and (l.mo_chon_de_tai_luc is null or l.mo_chon_de_tai_luc <= now())
      and (l.dong_chon_de_tai_luc is null or l.dong_chon_de_tai_luc >= now())
  );
$$;

create or replace function public.sinh_vien_duoc_tao_nhom(p_lop_do_an_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.lop_do_an l
    where l.id = p_lop_do_an_id
      and l.cho_phep_sinh_vien_tao_nhom = true
      and l.trang_thai = 'mo_dang_ky'
  )
  and public.la_sinh_vien_da_ghi_danh(p_lop_do_an_id)
  and public.chua_co_nhom_trong_lop_hien_tai(p_lop_do_an_id)
  and public.lop_do_an_dang_mo_dang_ky(p_lop_do_an_id);
$$;

create or replace function public.co_the_xem_ho_so(p_ho_so_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(auth.uid() = p_ho_so_id, false)
     or public.la_quan_tri_vien()
     or public.vai_tro_hien_tai() = 'giang_vien';
$$;


-- TRIGGER / FUNCTION 
create or replace function public.tao_ho_so_nguoi_dung_moi()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.ho_so (
    id, email, ho_ten, vai_tro
  )
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'ho_ten',
      split_part(coalesce(new.email, new.phone, new.id::text), '@', 1)
    ),
    case
      when coalesce(new.raw_user_meta_data ->> 'role', '') in ('teacher', 'giang_vien') then 'giang_vien'::public.vai_tro_ung_dung
      when coalesce(new.raw_user_meta_data ->> 'role', '') in ('admin', 'quan_tri_vien') then 'quan_tri_vien'::public.vai_tro_ung_dung
      else 'sinh_vien'::public.vai_tro_ung_dung
    end
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger tg_auth_tao_ho_so
after insert on auth.users
for each row
execute function public.tao_ho_so_nguoi_dung_moi();

create or replace function public.bao_ve_ho_so_khi_cap_nhat()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.cap_nhat_luc := now();
  return new;
end;
$$;

create trigger tg_ho_so_cap_nhat_luc
before update on public.ho_so
for each row
execute function public.bao_ve_ho_so_khi_cap_nhat();

create trigger tg_lop_do_an_cap_nhat_luc
before update on public.lop_do_an
for each row
execute function public.dat_cap_nhat_luc();

create trigger tg_ghi_danh_cap_nhat_luc
before update on public.ghi_danh
for each row
execute function public.dat_cap_nhat_luc();

create or replace function public.bao_ve_nhom_do_an_khi_cap_nhat()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.la_quan_tri_vien()
     and not public.la_giang_vien_phu_trach_lop(old.lop_do_an_id)
     and not public.la_nhom_truong_hien_tai(old.id) then
    new.lop_do_an_id := old.lop_do_an_id;
    new.tao_boi := old.tao_boi;
    new.trang_thai := old.trang_thai;
    new.duyet_boi := old.duyet_boi;
    new.duyet_luc := old.duyet_luc;
    new.khoa_luc := old.khoa_luc;
    new.tao_luc := old.tao_luc;
  end if;

  new.cap_nhat_luc := now();
  return new;
end;
$$;

create trigger tg_nhom_do_an_bao_ve
before update on public.nhom_do_an
for each row
execute function public.bao_ve_nhom_do_an_khi_cap_nhat();

create or replace function public.tu_them_nhom_truong_sau_khi_tao_nhom()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
    from public.ghi_danh g
    where g.lop_do_an_id = new.lop_do_an_id
      and g.sinh_vien_id = new.tao_boi
      and g.trang_thai = 'da_duyet'
  ) then
    insert into public.thanh_vien_nhom (
      lop_do_an_id, nhom_id, sinh_vien_id, vai_tro, trang_thai, tham_gia_luc, moi_boi
    )
    values (
      new.lop_do_an_id,
      new.id,
      new.tao_boi,
      'nhom_truong',
      'da_chap_nhan',
      now(),
      new.tao_boi
    )
    on conflict (nhom_id, sinh_vien_id) do nothing;
  end if;

  return new;
end;
$$;

create trigger tg_nhom_do_an_tu_them_nhom_truong
after insert on public.nhom_do_an
for each row
execute function public.tu_them_nhom_truong_sau_khi_tao_nhom();

create or replace function public.kiem_tra_nhom_do_an_truoc_khi_them()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vai_tro public.vai_tro_ung_dung;
  v_can_duyet boolean;
begin
  if auth.uid() is null then
    return new;
  end if;

  select h.vai_tro into v_vai_tro
  from public.ho_so h
  where h.id = auth.uid();

  select l.can_giang_vien_duyet into v_can_duyet
  from public.lop_do_an l
  where l.id = new.lop_do_an_id;

  if v_vai_tro = 'sinh_vien' then
    if new.tao_boi <> auth.uid() then
      raise exception 'Chi duoc tao bang tai khoan cua minh.';
    end if;

    if not public.la_sinh_vien_da_ghi_danh(new.lop_do_an_id) then
      raise exception 'Sinh vien chua ghi danh vao lop do an.';
    end if;

    if not public.chua_co_nhom_trong_lop_hien_tai(new.lop_do_an_id) then
      raise exception 'Sinh vien da co nhom trong lop nay.';
    end if;

    new.trang_thai :=
      case
        when coalesce(v_can_duyet, true) then 'cho_duyet'::public.trang_thai_nhom
        else 'da_duyet'::public.trang_thai_nhom
      end;
  end if;

  return new;
end;
$$;

create trigger tg_nhom_do_an_kiem_tra_them
before insert on public.nhom_do_an
for each row
execute function public.kiem_tra_nhom_do_an_truoc_khi_them();

create or replace function public.bao_ve_de_tai_khi_cap_nhat()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null
     and not public.la_quan_tri_vien()
     and not public.la_giang_vien_phu_trach_lop(old.lop_do_an_id) then
    new.id := old.id;
    new.lop_do_an_id := old.lop_do_an_id;
    new.giang_vien_id := old.giang_vien_id;
    new.ma_de_tai := old.ma_de_tai;
    new.ten_de_tai := old.ten_de_tai;
    new.mo_ta := old.mo_ta;
    new.muc_tieu := old.muc_tieu;
    new.yeu_cau := old.yeu_cau;
    new.cong_nghe := old.cong_nghe;
    new.san_pham_ban_giao := old.san_pham_ban_giao;
    new.so_thanh_vien_toi_thieu := old.so_thanh_vien_toi_thieu;
    new.so_thanh_vien_toi_da := old.so_thanh_vien_toi_da;
    new.tao_boi := old.tao_boi;
    new.duyet_boi := old.duyet_boi;
    new.cong_bo_luc := old.cong_bo_luc;
  end if;

  new.cap_nhat_luc := now();
  return new;
end;
$$;

create trigger tg_de_tai_bao_ve
before update on public.de_tai
for each row
execute function public.bao_ve_de_tai_khi_cap_nhat();

create or replace function public.kiem_tra_nguyen_vong_truoc_khi_them()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_vai_tro public.vai_tro_ung_dung;
begin
  if auth.uid() is null then
    return new;
  end if;

  select h.vai_tro into v_vai_tro
  from public.ho_so h
  where h.id = auth.uid();

  if v_vai_tro = 'sinh_vien' then
    if new.tao_boi <> auth.uid() then
      raise exception 'Chi duoc tao nguyen vong bang tai khoan cua minh.';
    end if;

    if not public.la_nhom_truong_hien_tai(new.nhom_id) then
      raise exception 'Chi truong nhom hien tai moi duoc tao nguyen vong.';
    end if;

    if not public.la_sinh_vien_da_ghi_danh(new.lop_do_an_id) then
      raise exception 'Nhom chua ghi danh hop le vao lop do an.';
    end if;
  end if;

  return new;
end;
$$;

create trigger tg_nguyen_vong_kiem_tra_them
before insert on public.nguyen_vong_de_tai
for each row
execute function public.kiem_tra_nguyen_vong_truoc_khi_them();

create or replace function public.xu_ly_nguyen_vong_sau_khi_cap_nhat()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.trang_thai = 'da_duyet' and old.trang_thai <> 'da_duyet' then
    update public.de_tai
       set nhom_id = new.nhom_id,
           trang_thai = 'da_gan_nhom',
           duyet_boi = coalesce(new.duyet_boi, auth.uid()),
           cong_bo_luc = coalesce(cong_bo_luc, now()),
           cap_nhat_luc = now()
     where id = new.de_tai_id;
  end if;

  if new.trang_thai = 'tu_choi' and old.trang_thai <> 'tu_choi' then
    new.duyet_boi := coalesce(new.duyet_boi, auth.uid());
    new.duyet_luc := coalesce(new.duyet_luc, now());
  end if;

  return new;
end;
$$;

create trigger tg_nguyen_vong_xu_ly_sau_cap_nhat
before update on public.nguyen_vong_de_tai
for each row
execute function public.xu_ly_nguyen_vong_sau_khi_cap_nhat();


--  RPC / TIỆN ÍCH

create or replace function public.gui_thong_bao(
  p_nguoi_nhan_id uuid,
  p_tieu_de text,
  p_noi_dung text,
  p_loai text default 'he_thong',
  p_duong_dan text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.thong_bao_he_thong (
    nguoi_nhan_id, tieu_de, noi_dung, loai, duong_dan, tao_boi
  )
  values (
    p_nguoi_nhan_id,
    p_tieu_de,
    p_noi_dung,
    coalesce(p_loai, 'he_thong'),
    p_duong_dan,
    auth.uid()
  );
end;
$$;

create or replace function public.ghi_nhat_ky(
  p_hanh_dong text,
  p_loai_doi_tuong text,
  p_doi_tuong_id uuid default null,
  p_du_lieu jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.nhat_ky_he_thong (
    nguoi_thuc_hien_id, hanh_dong, loai_doi_tuong, doi_tuong_id, du_lieu
  )
  values (
    auth.uid(),
    p_hanh_dong,
    p_loai_doi_tuong,
    p_doi_tuong_id,
    coalesce(p_du_lieu, '{}'::jsonb)
  );
end;
$$;


-- INDEXES

create index ix_lop_do_an_giang_vien_id on public.lop_do_an(giang_vien_id);
create index ix_ghi_danh_lop_do_an_id on public.ghi_danh(lop_do_an_id);
create index ix_ghi_danh_sinh_vien_id on public.ghi_danh(sinh_vien_id);
create index ix_nhom_do_an_lop_do_an_id on public.nhom_do_an(lop_do_an_id);
create index ix_thanh_vien_nhom_nhom_id on public.thanh_vien_nhom(nhom_id);
create index ix_thanh_vien_nhom_lop_do_an_id on public.thanh_vien_nhom(lop_do_an_id);
create index ix_de_tai_lop_do_an_id on public.de_tai(lop_do_an_id);
create index ix_de_tai_nhom_id on public.de_tai(nhom_id);
create index ix_nguyen_vong_de_tai_nhom_id on public.nguyen_vong_de_tai(nhom_id);
create index ix_nguyen_vong_de_tai_de_tai_id on public.nguyen_vong_de_tai(de_tai_id);
create index ix_yeu_cau_vao_nhom_nhom_id on public.yeu_cau_vao_nhom(nhom_id);
create index ix_thong_bao_he_thong_nguoi_nhan_id on public.thong_bao_he_thong(nguoi_nhan_id);
create index ix_nhat_ky_he_thong_nguoi_thuc_hien_id on public.nhat_ky_he_thong(nguoi_thuc_hien_id);

create unique index uq_thanh_vien_nhom_mot_nhom_truong
on public.thanh_vien_nhom (nhom_id)
where vai_tro = 'nhom_truong' and trang_thai = 'da_chap_nhan';

create unique index uq_thanh_vien_nhom_mot_sinh_vien_mot_nhom_trong_mot_lop
on public.thanh_vien_nhom (lop_do_an_id, sinh_vien_id)
where trang_thai = 'da_chap_nhan';


-- =========================================================
-- 7) KÍCH HOẠT BẢO MẬT RLS (ROW LEVEL SECURITY)

alter table public.ho_so enable row level security;
alter table public.lop_do_an enable row level security;
alter table public.ghi_danh enable row level security;
alter table public.nhom_do_an enable row level security;
alter table public.thanh_vien_nhom enable row level security;
alter table public.de_tai enable row level security;
alter table public.nguyen_vong_de_tai enable row level security;
alter table public.yeu_cau_vao_nhom enable row level security;
alter table public.thong_bao_he_thong enable row level security;
alter table public.nhat_ky_he_thong enable row level security;


-- 8) CHÍNH SÁCH BẢO MẬT RLS 


-- HỒ SƠ (HO_SO)
create policy p_ho_so_xem on public.ho_so
for select to authenticated
using (true);

create policy p_ho_so_cap_nhat_cua_minh on public.ho_so
for update to authenticated
using (auth.uid() = id or public.la_quan_tri_vien())
with check (auth.uid() = id or public.la_quan_tri_vien());

-- LỚP ĐỒ ÁN (LOP_DO_AN)
create policy p_lop_do_an_xem on public.lop_do_an
for select to authenticated
using (true);

create policy p_lop_do_an_quan_ly on public.lop_do_an
for all to authenticated
using (public.la_quan_tri_vien() or giang_vien_id = auth.uid())
with check (public.la_quan_tri_vien() or giang_vien_id = auth.uid());

-- GHI DANH (GHI_DANH)
create policy p_ghi_danh_xem on public.ghi_danh
for select to authenticated
using (true);

create policy p_ghi_danh_them on public.ghi_danh
for insert to authenticated
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or (sinh_vien_id = auth.uid() and public.lop_do_an_dang_mo_dang_ky(lop_do_an_id))
);

create policy p_ghi_danh_sua on public.ghi_danh
for update to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or sinh_vien_id = auth.uid()
)
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or (sinh_vien_id = auth.uid() and public.lop_do_an_dang_mo_dang_ky(lop_do_an_id))
);

-- NHÓM ĐỒ ÁN (NHOM_DO_AN)
create policy p_nhom_do_an_xem on public.nhom_do_an
for select to authenticated
using (true);

create policy p_nhom_do_an_them on public.nhom_do_an
for insert to authenticated
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or (tao_boi = auth.uid() and public.sinh_vien_duoc_tao_nhom(lop_do_an_id))
);

create policy p_nhom_do_an_sua on public.nhom_do_an
for update to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(id)
)
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(id)
);

create policy p_nhom_do_an_xoa on public.nhom_do_an
for delete to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or tao_boi = auth.uid()
);

-- THÀNH VIÊN NHÓM (THANH_VIEN_NHOM)
create policy p_thanh_vien_nhom_xem on public.thanh_vien_nhom
for select to authenticated
using (true);

create policy p_thanh_vien_nhom_them on public.thanh_vien_nhom
for insert to authenticated
with check (true);

create policy p_thanh_vien_nhom_sua on public.thanh_vien_nhom
for update to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
  or sinh_vien_id = auth.uid()
)
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
  or sinh_vien_id = auth.uid()
);

create policy p_thanh_vien_nhom_xoa on public.thanh_vien_nhom
for delete to authenticated
using (true);

-- ĐỀ TÀI (DE_TAI)
create policy p_de_tai_xem on public.de_tai
for select to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_sinh_vien_da_ghi_danh(lop_do_an_id)
);

create policy p_de_tai_quan_ly on public.de_tai
for insert to authenticated
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
);

create policy p_de_tai_sua on public.de_tai
for update to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
)
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
);

create policy p_de_tai_xoa on public.de_tai
for delete to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
);

-- NGUYỆN VỌNG ĐỀ TÀI (NGUYEN_VONG_DE_TAI)
create policy p_nguyen_vong_xem on public.nguyen_vong_de_tai
for select to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
);

create policy p_nguyen_vong_them on public.nguyen_vong_de_tai
for insert to authenticated
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or (tao_boi = auth.uid() and public.la_nhom_truong_hien_tai(nhom_id) and public.lop_do_an_dang_mo_chon_de_tai(lop_do_an_id))
);

create policy p_nguyen_vong_sua on public.nguyen_vong_de_tai
for update to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
)
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
);

create policy p_nguyen_vong_xoa on public.nguyen_vong_de_tai
for delete to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
);

-- YÊU CẦU VÀO NHÓM (YEU_CAU_VAO_NHOM)
create policy p_yeu_cau_xem on public.yeu_cau_vao_nhom
for select to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or sinh_vien_id = auth.uid()
  or public.la_nhom_truong_hien_tai(nhom_id)
);

create policy p_yeu_cau_them on public.yeu_cau_vao_nhom
for insert to authenticated
with check (
  sinh_vien_id = auth.uid()
  and public.la_sinh_vien_da_ghi_danh(lop_do_an_id)
  and public.chua_co_nhom_trong_lop_hien_tai(lop_do_an_id)
  and public.lop_do_an_dang_mo_dang_ky(lop_do_an_id)
);

create policy p_yeu_cau_sua on public.yeu_cau_vao_nhom
for update to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
  or sinh_vien_id = auth.uid()
)
with check (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
  or sinh_vien_id = auth.uid()
);

create policy p_yeu_cau_xoa on public.yeu_cau_vao_nhom
for delete to authenticated
using (
  public.la_quan_tri_vien()
  or public.la_giang_vien_phu_trach_lop(lop_do_an_id)
  or public.la_nhom_truong_hien_tai(nhom_id)
  or sinh_vien_id = auth.uid()
);

-- THÔNG BÁO (THONG_BAO_HE_THONG)
create policy p_thong_bao_xem on public.thong_bao_he_thong
for select to authenticated
using (
  public.la_quan_tri_vien()
  or nguoi_nhan_id = auth.uid()
);

create policy p_thong_bao_them on public.thong_bao_he_thong
for insert to authenticated
with check (true);

create policy p_thong_bao_sua on public.thong_bao_he_thong
for update to authenticated
using (
  public.la_quan_tri_vien()
  or nguoi_nhan_id = auth.uid()
)
with check (
  public.la_quan_tri_vien()
  or nguoi_nhan_id = auth.uid()
);

create policy p_thong_bao_xoa on public.thong_bao_he_thong
for delete to authenticated
using (public.la_quan_tri_vien() or nguoi_nhan_id = auth.uid());

-- NHẬT KÝ (NHAT_KY_HE_THONG)
create policy p_nhat_ky_xem on public.nhat_ky_he_thong
for select to authenticated
using (public.la_quan_tri_vien());

create policy p_nhat_ky_them on public.nhat_ky_he_thong
for insert to authenticated
with check (true);

-- =========================================================
-- 9) KHỞI TẠO TÀI KHOẢN MẪU

create or replace function public.tao_tai_khoan_mau(
  p_id uuid,
  p_email text,
  p_mat_khau text,
  p_ho_ten text,
  p_vai_tro public.vai_tro_ung_dung,
  p_ma_sinh_vien text default null,
  p_ma_giang_vien text default null,
  p_lop_hanh_chinh text default null,
  p_khoa text default null,
  p_nganh text default null,
  p_so_dien_thoai text default null
)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_role_text text;
begin
  v_role_text := case
    when p_vai_tro = 'sinh_vien' then 'sinh_vien'
    when p_vai_tro = 'giang_vien' then 'giang_vien'
    else 'quan_tri_vien'
  end;

  if not exists (select 1 from auth.users where id = p_id) then
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      p_id,
      'authenticated',
      'authenticated',
      p_email,
      extensions.crypt(p_mat_khau, extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      jsonb_build_object('full_name', p_ho_ten, 'role', v_role_text),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  end if;

  if not exists (
    select 1
    from auth.identities
    where user_id = p_id and provider = 'email'
  ) then
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
    )
    values (
      extensions.gen_random_uuid(),
      p_id,
      jsonb_build_object('sub', p_id::text, 'email', p_email, 'email_verified', true),
      'email',
      p_id::text,
      now(),
      now(),
      now()
    );
  end if;

  insert into public.ho_so (
    id, email, ho_ten, vai_tro, ma_sinh_vien, ma_giang_vien, lop_hanh_chinh, khoa, nganh, so_dien_thoai, dang_hoat_dong, tao_luc, cap_nhat_luc
  )
  values (
    p_id, p_email, p_ho_ten, p_vai_tro, p_ma_sinh_vien, p_ma_giang_vien, p_lop_hanh_chinh, p_khoa, p_nganh, p_so_dien_thoai, true, now(), now()
  )
  on conflict (id) do update
  set email = excluded.email,
      ho_ten = excluded.ho_ten,
      vai_tro = excluded.vai_tro,
      ma_sinh_vien = excluded.ma_sinh_vien,
      ma_giang_vien = excluded.ma_giang_vien,
      lop_hanh_chinh = excluded.lop_hanh_chinh,
      khoa = excluded.khoa,
      nganh = excluded.nganh,
      so_dien_thoai = excluded.so_dien_thoai,
      cap_nhat_luc = now();
end;
$$;
