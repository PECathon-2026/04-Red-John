/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
  async redirects() {
    return [
      {
        source: '/teams',
        destination: '/team',
        permanent: true,
      },
    ]
  },
}

export default nextConfig
