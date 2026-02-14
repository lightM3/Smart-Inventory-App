-- 1. TENANTS (Şirketler/Marketler) Tablosu
CREATE TABLE IF NOT EXISTS public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS (Sadece sistem okusun veya belirli yetkiler okusun, şimdilik public yapalım)
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Tenants are viewable by authenticated users." ON public.tenants FOR SELECT USING (auth.role() = 'authenticated');


-- 2. PROFILES Tablosu (tenant_id ve role eklendi)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  tenant_id UUID REFERENCES public.tenants(id) NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'staff', -- 'admin', 'staff', 'manager'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- DÜZELTİLMİŞ RLS: Sonsuz döngüyü (infinite recursion) önlemek
-- için SECURITY DEFINER fonksiyonu kullanılıyor.
-- Fonksiyon profiles tablosunu RLS'i ATLAYARAK okuduğu için döngü oluşmaz.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_my_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT tenant_id FROM public.profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$;

-- Kullanıcı sadece kendi tenant_id'sine sahip profilleri görebilir
CREATE POLICY "Users can view profiles in their tenant" 
ON public.profiles FOR SELECT 
USING (tenant_id = public.get_my_tenant_id());

-- Yalnızca Adminler kendi tenant_id'leri içinde profil güncelleyebilir
CREATE POLICY "Admins can update profiles" 
ON public.profiles FOR UPDATE 
USING (
  public.get_my_role() = 'admin' 
  AND tenant_id = public.get_my_tenant_id()
);


-- 3. PRODUCTS Tablosu
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY,
  tenant_id UUID REFERENCES public.tenants(id) NOT NULL,
  title TEXT NOT NULL,
  barcode TEXT,
  category TEXT NOT NULL,
  quantity NUMERIC NOT NULL DEFAULT 0,
  min_stock_level NUMERIC NOT NULL DEFAULT 0,
  price NUMERIC NOT NULL DEFAULT 0,
  image_path TEXT,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their tenant products" 
ON public.products FOR SELECT 
USING (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert their tenant products" 
ON public.products FOR INSERT 
WITH CHECK (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their tenant products" 
ON public.products FOR UPDATE 
USING (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can delete their tenant products" 
ON public.products FOR DELETE 
USING (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));


-- 4. CATEGORIES Tablosu
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY,
  tenant_id UUID REFERENCES public.tenants(id) NOT NULL,
  name TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  icon_code_point INTEGER NOT NULL,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their tenant categories" 
ON public.categories FOR SELECT 
USING (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert their tenant categories" 
ON public.categories FOR INSERT 
WITH CHECK (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their tenant categories" 
ON public.categories FOR UPDATE 
USING (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can delete their tenant categories" 
ON public.categories FOR DELETE 
USING (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));


-- 5. TRANSACTIONS Tablosu (Stok Hareketleri)
-- performed_by eklendi
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY,
  tenant_id UUID REFERENCES public.tenants(id) NOT NULL,
  product_sync_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'inbound' or 'outbound'
  quantity NUMERIC NOT NULL,
  reason TEXT NOT NULL,
  note TEXT,
  performed_by TEXT, -- Kasiyerin veya işlemi yapanın Adı/ID'si
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their tenant transactions" 
ON public.transactions FOR SELECT 
USING (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert their tenant transactions" 
ON public.transactions FOR INSERT 
WITH CHECK (tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid()));

-- Update ve Delete yetkisi sadece Adminlere verilebilir (opsiyonel ekstra güvenlik)
CREATE POLICY "Admins can update transactions" 
ON public.transactions FOR UPDATE 
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin' 
  AND tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid())
);

CREATE POLICY "Admins can delete transactions" 
ON public.transactions FOR DELETE 
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin' 
  AND tenant_id = (SELECT tenant_id FROM public.profiles WHERE id = auth.uid())
);

-- === MEVCUT VERİTABANI ŞEMASINI GÜNCELLEMEK İÇİN ===
-- products tablosu zaten oluşturulmuşsa, fiyat kolonunu eklemek için bu komutu çalıştırın:
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS price NUMERIC NOT NULL DEFAULT 0;
